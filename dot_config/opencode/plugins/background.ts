import { tool, type Plugin } from "@opencode-ai/plugin"
import { execFileSync } from "node:child_process"
import {
  closeSync,
  existsSync,
  mkdirSync,
  openSync,
  readFileSync,
  readSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"
import { randomBytes } from "node:crypto"

const PLUGIN_NAME = "background-plugin"
const JOBS_DIR = join(homedir(), ".local", "state", "opencode", "bg-jobs")
const PREFIX = "bg-"
const PRUNE_DAYS = 30
const CAP_LINES = 2000
const PREVIEW_LINES = 50
const RECENT_MS = 24 * 60 * 60 * 1000
const LOG_CHUNK = 2_000_000

type JobKind = "oneshot" | "session"
type JobStatus = "running" | "finished" | "failed" | "interrupted" | "killed" | "closed"

type JobRecord = {
  id: string
  name?: string
  kind: JobKind
  command: string
  cwd: string
  tmuxSession: string
  status: JobStatus
  exitCode?: number
  createdAt: string
  endedAt?: string
}

type Out = string

let warnLog: (message: string) => void = () => {}

const recPath = (id: string) => join(JOBS_DIR, `${id}.json`)
const logPath = (id: string) => join(JOBS_DIR, `${id}.log`)
const exitPath = (id: string) => join(JOBS_DIR, `${id}.exit`)
const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms))
const shq = (s: string) => `'${s.replaceAll("'", `'\\''`)}'`
const nowIso = () => new Date().toISOString()

function tmux(args: string[]): string {
  try {
    return execFileSync("tmux", args, { timeout: 5000, encoding: "utf8" })
  } catch (e) {
    const err = e as { stderr?: Buffer | string; stdout?: Buffer | string; message?: string }
    const detail = [err.stdout?.toString(), err.stderr?.toString()].filter(Boolean).join("\n").trim()
    throw new Error(`tmux ${args[0]} failed: ${detail || err.message || String(e)}`)
  }
}

function tmuxOk(args: string[]): boolean {
  try {
    execFileSync("tmux", args, { timeout: 5000, stdio: "ignore" })
    return true
  } catch {
    return false
  }
}

const hasSession = (name: string) => tmuxOk(["has-session", "-t", name])

function windowTarget(name: string): string {
  const idx = execFileSync("tmux", ["display-message", "-p", "-t", name, "#{window_index}"], {
    timeout: 5000,
    encoding: "utf8",
  }).trim()
  return `${name}:${idx}`
}

function capturePane(name: string, lines: number): string {
  try {
    return execFileSync("tmux", ["capture-pane", "-p", "-t", `${windowTarget(name)}.0`, "-S", `-${lines}`], {
      timeout: 5000,
      encoding: "utf8",
    })
  } catch {
    return ""
  }
}

function ensureDir() {
  mkdirSync(JOBS_DIR, { recursive: true })
}

function readExitCode(id: string): number | null {
  try {
    const v = Number.parseInt(readFileSync(exitPath(id), "utf8").trim(), 10)
    return Number.isFinite(v) ? v : null
  } catch {
    return null
  }
}

function readRecord(id: string): JobRecord | null {
  try {
    return JSON.parse(readFileSync(recPath(id), "utf8")) as JobRecord
  } catch {
    return null
  }
}

function writeRecord(rec: JobRecord) {
  ensureDir()
  writeFileSync(recPath(rec.id), JSON.stringify(rec, null, 2))
}

function listRecords(): JobRecord[] {
  if (!existsSync(JOBS_DIR)) return []
  const out: JobRecord[] = []
  for (const e of readdirSync(JOBS_DIR, { withFileTypes: true })) {
    if (!e.isFile() || !e.name.endsWith(".json")) continue
    const id = e.name.slice(0, -".json".length)
    const rec = readRecord(id)
    if (!rec) {
      warnLog(`skipping corrupt job record: ${e.name}`)
      continue
    }
    if (rec.id !== id) {
      warnLog(`skipping job record with mismatched id: ${e.name}`)
      continue
    }
    out.push(rec)
  }
  return out
}

function reconcile(rec: JobRecord): JobRecord {
  if (rec.status !== "running") return rec
  const ec = readExitCode(rec.id)
  if (ec !== null) {
    rec.status = ec === 0 ? "finished" : "failed"
    rec.exitCode = ec
    rec.endedAt = rec.endedAt ?? nowIso()
  } else if (!hasSession(rec.tmuxSession)) {
    rec.status = rec.kind === "session" ? "closed" : "interrupted"
    rec.endedAt = nowIso()
  } else {
    return rec
  }
  writeRecord(rec)
  return rec
}

function readLogChunk(id: string): string {
  const file = logPath(id)
  if (!existsSync(file)) return ""
  const size = statSync(file).size
  if (size === 0) return ""
  const start = Math.max(0, size - LOG_CHUNK)
  const buf = Buffer.alloc(size - start)
  const fd = openSync(file, "r")
  try {
    readSync(fd, buf, 0, buf.length, start)
  } finally {
    closeSync(fd)
  }
  return buf.toString("utf8")
}

function cleanLine(l: string): string {
  return l
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "")
    // eslint-disable-next-line no-control-regex
    .replace(/\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b[()][0-9A-B]|\x1b[=>]/g, "")
    .replace(/[ \t]+$/g, "")
}

function splitLines(raw: string): string[] {
  const lines = raw.split("\n").map(cleanLine)
  if (lines.at(-1) === "") lines.pop()
  while (lines.length > 0 && lines[0] === "") lines.shift()
  return lines
}

function outputLines(rec: JobRecord): string[] {
  const chunk = readLogChunk(rec.id)
  if (chunk) {
    return splitLines(chunk)
  }
  if (hasSession(rec.tmuxSession)) {
    const pane = capturePane(rec.tmuxSession, CAP_LINES)
    if (pane) return splitLines(pane)
  }
  return []
}

function startJob(rec: JobRecord, rawCommand: string) {
  const log = logPath(rec.id)
  const exit = exitPath(rec.id)
  const inner =
    rec.kind === "oneshot"
      ? `( ${rawCommand} )\nec=$?\nprintf %s "$ec" > ${shq(exit)}\nexit $ec`
      : rawCommand.trim()
        ? `exec ${rawCommand}`
        : "exec bash"
  tmux(["new-session", "-d", "-s", rec.tmuxSession, "-c", rec.cwd, `bash -c ${shq(inner)}`])
  const win = windowTarget(rec.tmuxSession)
  tmux(["pipe-pane", "-o", "-t", win, `cat >> ${shq(log)}`])
}

class ToolError extends Error {}

function resolve(ref: string): JobRecord {
  const recs = listRecords()
  const matches = [
    ...recs.filter((r) => r.id === ref),
    ...recs.filter((r) => r.name === ref),
    ...recs.filter((r) => r.tmuxSession === ref),
  ]
  const uniq = matches.filter((r, i) => matches.findIndex((x) => x.id === r.id) === i)
  if (uniq.length > 1) {
    throw new ToolError(`Ambiguous reference "${ref}" matches jobs: ${uniq.map((r) => r.id).join(", ")}.`)
  }
  const rec = uniq[0]
  if (!rec) {
    throw new ToolError(
      `No job matches "${ref}". Known ids: ${recs.map((r) => r.id).join(", ") || "none"}. Call bg_list.`,
    )
  }
  return rec
}

function uniqueId(): string {
  for (let i = 0; i < 100; i++) {
    const id = `job-${randomBytes(3).toString("hex")}`
    if (!existsSync(recPath(id))) return id
  }
  return `job-${Date.now()}`
}

const sanitize = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40)

function formatRuntime(rec: JobRecord): string {
  const start = Date.parse(rec.createdAt)
  const end = rec.endedAt ? Date.parse(rec.endedAt) : Date.now()
  const secs = Math.max(0, Math.round((end - start) / 1000))
  if (secs < 60) return `${secs}s`
  return `${Math.floor(secs / 60)}m${String(secs % 60).padStart(2, "0")}s`
}

function recentLines(rec: JobRecord, n: number): string[] {
  return outputLines(rec).slice(-n)
}

const wrap = (tag: string, lines: string[]) => [`<${tag}>`, ...lines, `</${tag}>`].join("\n")
const ok = (lines: string[]) => wrap("tool-success", lines)
const err = (lines: string[]) => wrap("tool-error", lines)
const info = (lines: string[]) => wrap("tool-info", lines)

async function guarded(fn: () => Out | Promise<Out>): Promise<Out> {
  try {
    return await fn()
  } catch (e) {
    if (e instanceof ToolError) return err([e.message])
    return err([e instanceof Error ? e.message : String(e)])
  }
}

const refArg = tool.schema.string().describe("Job id (e.g. job-1a2b3c), human name, or tmux session name")

const bgStart = tool({
  description:
    "Start a command in the background as a tmux-backed job with persistent output logging. " +
    "Returns a job id, the tmux session name, an attach hint, the log path, and the first output lines. " +
    "Use session=true for long-lived interactive sessions (no command = local shell, or command like 'ssh host'); " +
    "drive them later with bg_send and bg_output. Otherwise the command is a oneshot whose exit code bg_status reports. " +
    "Jobs survive opencode restarts; after a reboot finished/interrupted state is preserved from logs.",
  args: {
    command: tool.schema
      .string()
      .optional()
      .describe("Shell command to run. Optional when session=true (defaults to an interactive bash)."),
    name: tool.schema.string().optional().describe("Optional human-friendly name; usable as the job reference."),
    session: tool.schema.boolean().default(false).describe("true = long-lived interactive session (shell/ssh) instead of a one-shot command."),
    cwd: tool.schema.string().optional().describe("Working directory. Defaults to the current project directory."),
  },
  async execute(args, ctx) {
    return guarded(async () => {
      const kind: JobKind = args.session ? "session" : "oneshot"
      const command = (args.command ?? "").trim()
      if (!args.session && !command) return err(["command is required for a one-shot job."])
      const dir = args.cwd ?? ctx.directory
      if (!existsSync(dir)) return err([`cwd does not exist: ${dir}`])
      ensureDir()
      if (args.name) {
        const dup = listRecords().find((r) => r.name === args.name)
        if (dup) return err([`A job named "${args.name}" already exists: ${dup.id} (${dup.status}).`])
      }
      const id = uniqueId()
      const tmuxSession = PREFIX + (args.name ? sanitize(args.name) : id.slice("job-".length))
      if (hasSession(tmuxSession)) {
        return err([`tmux session "${tmuxSession}" already exists. Pick a different name or bg_kill the old job.`])
      }
      const rec: JobRecord = {
        id,
        name: args.name,
        kind,
        command: command || "(interactive bash)",
        cwd: dir,
        tmuxSession,
        status: "running",
        createdAt: nowIso(),
      }
      writeRecord(rec)
      try {
        startJob(rec, command || "")
      } catch (e) {
        rec.status = "killed"
        rec.endedAt = nowIso()
        writeRecord(rec)
        return err([`Failed to start job: ${e instanceof Error ? e.message : String(e)}`])
      }
      let lines: string[] = []
      for (let i = 0; i < 10; i++) {
        await sleep(100)
        lines = recentLines(rec, PREVIEW_LINES)
        if (lines.length > 0) break
      }
      const final = reconcile(readRecord(id) ?? rec)
      const preview = lines.length > 0 ? ["", "first output:", ...lines.map((l) => `  | ${l}`)] : ["", "(no output yet)"]
      return ok([
        `Job started: ${final.id} (${final.kind})${final.name ? ` name=${final.name}` : ""}`,
        `status: ${final.status}${final.exitCode !== undefined ? ` exit=${final.exitCode}` : ""}`,
        `tmux session: ${final.tmuxSession}  (attach: tmux attach -t ${final.tmuxSession})`,
        `log: ${logPath(final.id)}  (tail -f to follow)`,
        ...preview,
        `NEXT STEP: bg_status {id, wait} to check/wait for completion; bg_output to read; bg_send to interact (sessions); bg_kill to stop.`,
      ])
    })
  },
})

const bgStatus = tool({
  description:
    "Report a background job's status: running, finished (exit 0), failed (exit N), interrupted, killed, or closed. " +
    "Optionally block up to `wait` seconds until the job exits, then report its exit code. Also returns recent output.",
  args: {
    id: refArg,
    wait: tool.schema
      .number()
      .int()
      .min(0)
      .max(120)
      .optional()
      .describe("Seconds to wait for job completion before returning (polls every 250ms)."),
  },
  async execute(args) {
    return guarded(async () => {
      let rec = reconcile(resolve(args.id))
      const deadline = args.wait ? Date.now() + args.wait * 1000 : 0
      while (rec.status === "running" && Date.now() < deadline) {
        await sleep(250)
        rec = reconcile(readRecord(rec.id) ?? rec)
      }
      const lines = recentLines(rec, 5)
      return ok([
        `Job ${rec.id}${rec.name ? ` (${rec.name})` : ""} [${rec.kind}]`,
        `command: ${rec.command}`,
        `status: ${rec.status}${rec.exitCode !== undefined ? `  exit=${rec.exitCode}` : ""}`,
        `runtime: ${formatRuntime(rec)}  started: ${rec.createdAt}${rec.endedAt ? `  ended: ${rec.endedAt}` : ""}`,
        `log: ${logPath(rec.id)}`,
        ...(lines.length ? ["recent output:", ...lines.map((l) => `  | ${l}`)] : []),
        `NEXT STEP: ${
          rec.status === "running"
            ? "keep working and bg_status again (optionally wait=N), or bg_output for more output."
            : rec.status === "finished"
              ? "job succeeded; use bg_output for full output."
              : rec.status === "failed"
                ? "job failed; bg_output to inspect the error before retrying."
                : "use bg_list for an overview or bg_kill {purge:true} to clean up."
        }`,
      ])
    })
  },
})

const bgOutput = tool({
  description:
    "Read a background job's captured output: tail the last N lines, grep with a regex, or return recent output. " +
    "Response is capped (max_lines <= 2000). Works for finished and running jobs alike.",
  args: {
    id: refArg,
    tail: tool.schema.number().int().min(1).optional().describe("Return only the last N lines."),
    grep: tool.schema.string().optional().describe("Regex filter applied to the output."),
    max_lines: tool.schema
      .number()
      .int()
      .min(1)
      .max(CAP_LINES)
      .default(200)
      .describe("Cap on returned lines (default 200, max 2000)."),
  },
  async execute(args) {
    return guarded(async () => {
      const rec = reconcile(resolve(args.id))
      const all = outputLines(rec)
      let subset = all
      if (args.grep) {
        let re: RegExp
        try {
          re = new RegExp(args.grep)
        } catch {
          return err([`Invalid grep regex: ${args.grep}`])
        }
        subset = all.filter((l) => re.test(l))
      } else if (args.tail) {
        subset = all.slice(-args.tail)
      }
      const truncated = subset.length > args.max_lines
      const shown = subset.slice(-args.max_lines)
      return ok([
        `Job ${rec.id} [${rec.status}]  log lines in tail window: ${all.length}`,
        `returning ${shown.length}${truncated ? ` of ${subset.length} (truncated; use tail= or grep= to narrow)` : ""}`,
        ...(shown.length ? ["", ...shown.map((l) => `  | ${l}`)] : ["(no matching output)"]),
      ])
    })
  },
})

const bgSend = tool({
  description:
    "Send input to a running session's tmux pane (ssh prompts, pagers, confirmations, REPLs). " +
    "mode=text (default) sends the text followed by Enter; mode=keys sends tmux key names (Enter, Escape, C-c, Up...) without extra text.",
  args: {
    id: refArg,
    input: tool.schema.string().describe("Text to type, or tmux key name(s) when mode=keys (e.g. 'C-c' or 'Enter')."),
    mode: tool.schema.enum(["text", "keys"]).default("text").describe("text = literal text + Enter; keys = tmux key names, no Enter appended."),
  },
  async execute(args) {
    return guarded(async () => {
      const rec = reconcile(resolve(args.id))
      if (!hasSession(rec.tmuxSession)) {
        return err([`Job ${rec.id} has no live tmux session (status: ${rec.status}).`])
      }
      const target = `${windowTarget(rec.tmuxSession)}.0`
      if (args.mode === "text") {
        if (args.input.length > 0) tmux(["send-keys", "-t", target, "-l", args.input])
        tmux(["send-keys", "-t", target, "Enter"])
      } else {
        const keys = args.input.trim().split(/\s+/)
        if (keys.length === 0 || keys[0] === "") return err(["input is required when mode=keys."])
        tmux(["send-keys", "-t", target, ...keys])
      }
      await sleep(400)
      const lines = recentLines(rec, 10)
      return ok([
        `Sent to ${rec.tmuxSession}: ${args.mode === "text" ? JSON.stringify(args.input) + " + Enter" : args.input}`,
        ...(lines.length ? ["", "recent output:", ...lines.map((l) => `  | ${l}`)] : ["(no output yet)"]),
        `NEXT STEP: bg_output {id} to read the response; repeat bg_send for further interaction.`,
      ])
    })
  },
})

const bgKill = tool({
  description:
    "Kill a background job's tmux session and mark it killed (or finished/failed if it already exited). " +
    "purge=true also deletes the job's record and log files.",
  args: {
    id: refArg,
    purge: tool.schema.boolean().default(false).describe("Also delete the job record and log."),
  },
  async execute(args) {
    return guarded(async () => {
      const rec = reconcile(resolve(args.id))
      const killed = tmuxOk(["kill-session", "-t", rec.tmuxSession])
      if (rec.status === "running") {
        const ec = readExitCode(rec.id)
        rec.status = ec !== null ? (ec === 0 ? "finished" : "failed") : "killed"
        if (ec !== null) rec.exitCode = ec
        rec.endedAt = nowIso()
        writeRecord(rec)
      }
      if (args.purge) {
        for (const f of [recPath(rec.id), logPath(rec.id), exitPath(rec.id)]) rmSync(f, { force: true })
        return ok([
          `Job ${rec.id} purged: record, log${killed ? ", and tmux session" : " (tmux session already gone)"} removed.`,
          `NEXT STEP: bg_list to see remaining jobs.`,
        ])
      }
      return ok([
        `Job ${rec.id} [${rec.kind}]${rec.name ? ` (${rec.name})` : ""}: ${killed ? "tmux session killed" : "tmux session already gone"}, status now ${rec.status}${rec.exitCode !== undefined ? ` exit=${rec.exitCode}` : ""}.`,
        `Log kept at: ${logPath(rec.id)} (bg_kill {purge:true} to remove).`,
        `NEXT STEP: bg_list for remaining jobs.`,
      ])
    })
  },
})

const bgList = tool({
  description:
    "List background jobs: status, kind, id/name, runtime, exit code, tmux session name. " +
    "Default shows running jobs plus those finished in the last 24h; all=true shows every stored job.",
  args: {
    all: tool.schema.boolean().default(false).describe("Include all stored jobs, not just active/recent ones."),
  },
  async execute(args) {
    return guarded(async () => {
      ensureDir()
      const recs = listRecords().map(reconcile)
      const shown = args.all
        ? recs
        : recs.filter((r) => r.status === "running" || Date.parse(r.endedAt ?? r.createdAt) > Date.now() - RECENT_MS)
      shown.sort((a, b) => {
        const ar = a.status === "running" ? 0 : 1
        const br = b.status === "running" ? 0 : 1
        if (ar !== br) return ar - br
        return Date.parse(b.endedAt ?? b.createdAt) - Date.parse(a.endedAt ?? a.createdAt)
      })
      if (shown.length === 0) {
        return info([`No background jobs${args.all ? "" : " in the last 24h (try all=true)"}.`])
      }
      const lines = shown.map((r) => {
        const name = r.name ? `  name=${r.name}` : ""
        const ec = r.exitCode !== undefined ? `  exit=${r.exitCode}` : ""
        const cmd = r.command.length > 60 ? `${r.command.slice(0, 57)}...` : r.command
        return `${r.status.padEnd(11)} ${r.kind.padEnd(8)} ${r.id}${name}${ec}  ${formatRuntime(r)}  tmux=${r.tmuxSession}  ${cmd}`
      })
      return ok([
        `${shown.length} job(s)${args.all ? "" : " (running first, then recent)"}:`,
        ...lines,
        `NEXT STEP: bg_status {id} for detail; tmux attach -t <session> to watch live.`,
      ])
    })
  },
})

function reconcileAll(): number {
  if (!existsSync(JOBS_DIR)) return 0
  let n = 0
  for (const rec of listRecords()) {
    const before = rec.status
    reconcile(rec)
    if (rec.status !== before) n++
  }
  return n
}

function pruneFinished(): number {
  if (!existsSync(JOBS_DIR)) return 0
  const cutoff = Date.now() - PRUNE_DAYS * 86_400_000
  let n = 0
  for (const rec of listRecords()) {
    if (rec.kind === "session" || rec.status === "running") continue
    const t = Date.parse(rec.endedAt ?? rec.createdAt)
    if (Number.isFinite(t) && t < cutoff) {
      for (const f of [recPath(rec.id), logPath(rec.id), exitPath(rec.id)]) rmSync(f, { force: true })
      n++
    }
  }
  return n
}

export const BackgroundPlugin: Plugin = async ({ client }) => {
  warnLog = (message) => client?.app.log({ body: { service: PLUGIN_NAME, level: "warn", message } }).catch(() => {})
  const reconciled = reconcileAll()
  const pruned = pruneFinished()
  client?.app
    .log({
      body: {
        service: PLUGIN_NAME,
        level: "info",
        message: `initialized (reconciled ${reconciled} job(s), pruned ${pruned})`,
      },
    })
    .catch(() => {})
  return {
    tool: {
      bg_start: bgStart,
      bg_status: bgStatus,
      bg_output: bgOutput,
      bg_send: bgSend,
      bg_kill: bgKill,
      bg_list: bgList,
    },
  }
}

export default BackgroundPlugin