import { Plugin } from "@opencode/plugin"
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
      console.warn(`[${PLUGIN_NAME}] skipping corrupt job record: ${e.name}`)
      continue
    }
    if (rec.id !== id) {
      console.warn(`[${PLUGIN_NAME}] skipping job record with mismatched id: ${e.name}`)
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

async function guarded(fn: () => string | Promise<string>): Promise<{ content: string }> {
  try {
    return { content: await fn() }
  } catch (e) {
    if (e instanceof ToolError) return { content: err([e.message]) }
    return { content: err([e instanceof Error ? e.message : String(e)]) }
  }
}

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

export default Plugin.define({
  id: "background",
  async setup(ctx) {
    const reconciled = reconcileAll()
    const pruned = pruneFinished()
    console.log(`[${PLUGIN_NAME}] initialized (reconciled ${reconciled} job(s), pruned ${pruned})`)

    async function sessionDir(sessionID: string): Promise<string | undefined> {
      try {
        const session = await ctx.session.get({ sessionID })
        const dir = (session as unknown as { location?: { directory?: unknown } })?.location?.directory
        return typeof dir === "string" && dir.length > 0 ? dir : undefined
      } catch {
        return undefined
      }
    }

    const refProp = {
      type: "string",
      description: "Job id (e.g. job-1a2b3c), human name, or tmux session name",
    }

    const bgStart = {
      name: "bg_start",
      description:
        "Start a command in the background as a tmux-backed job with persistent output logging. " +
        "Returns a job id, the tmux session name, an attach hint, the log path, and the first output lines. " +
        "Use session=true for long-lived interactive sessions (no command = local shell, or command like 'ssh host'); " +
        "drive them later with bg_send and bg_output. Otherwise the command is a oneshot whose exit code bg_status reports. " +
        "Jobs survive opencode restarts; after a reboot finished/interrupted state is preserved from logs.",
      input: {
        type: "object",
        properties: {
          command: {
            type: "string",
            description: "Shell command to run. Optional when session=true (defaults to an interactive bash).",
          },
          name: {
            type: "string",
            description: "Optional human-friendly name; usable as the job reference.",
          },
          session: {
            type: "boolean",
            default: false,
            description:
              "true = long-lived interactive session (shell/ssh) instead of a one-shot command.",
          },
          cwd: {
            type: "string",
            description: "Working directory. Defaults to the current session directory.",
          },
        },
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        return guarded(async () => {
          const kind: JobKind = input.session ? "session" : "oneshot"
          const command = ((input.command as string | undefined) ?? "").trim()
          if (!input.session && !command) return err(["command is required for a one-shot job."])
          const dir = (input.cwd as string | undefined) ?? (await sessionDir(toolCtx.sessionID)) ?? process.cwd()
          if (!existsSync(dir)) return err([`cwd does not exist: ${dir}`])
          ensureDir()
          if (input.name) {
            const dup = listRecords().find((r) => r.name === input.name)
            if (dup) return err([`A job named "${input.name}" already exists: ${dup.id} (${dup.status}).`])
          }
          const id = uniqueId()
          const tmuxSession = PREFIX + (input.name ? sanitize(input.name) : id.slice("job-".length))
          if (hasSession(tmuxSession)) {
            return err([`tmux session "${tmuxSession}" already exists. Pick a different name or bg_kill the old job.`])
          }
          const rec: JobRecord = {
            id,
            name: input.name,
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
          const preview =
            lines.length > 0 ? ["", "first output:", ...lines.map((l) => `  | ${l}`)] : ["", "(no output yet)"]
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
    }

    const bgStatus = {
      name: "bg_status",
      description:
        "Report a background job's status: running, finished (exit 0), failed (exit N), interrupted, killed, or closed. " +
        "Optionally block up to `wait` seconds until the job exits, then report its exit code. Also returns recent output.",
      input: {
        type: "object",
        properties: {
          id: refProp,
          wait: {
            type: "integer",
            minimum: 0,
            maximum: 120,
            description: "Seconds to wait for job completion before returning (polls every 250ms).",
          },
        },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any) {
        return guarded(async () => {
          let rec = reconcile(resolve(input.id))
          const wait = input.wait as number | undefined
          const deadline = wait ? Date.now() + wait * 1000 : 0
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
    }

    const bgOutput = {
      name: "bg_output",
      description:
        "Read a background job's captured output: tail the last N lines, grep with a regex, or return recent output. " +
        "Response is capped (max_lines <= 2000). Works for finished and running jobs alike.",
      input: {
        type: "object",
        properties: {
          id: refProp,
          tail: { type: "integer", minimum: 1, description: "Return only the last N lines." },
          grep: { type: "string", description: "Regex filter applied to the output." },
          max_lines: {
            type: "integer",
            minimum: 1,
            maximum: CAP_LINES,
            default: 200,
            description: "Cap on returned lines (default 200, max 2000).",
          },
        },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any) {
        return guarded(async () => {
          const rec = reconcile(resolve(input.id))
          const all = outputLines(rec)
          const maxLines = Math.min(
            Math.max((input.max_lines as number | undefined) ?? 200, 1),
            CAP_LINES,
          )
          let subset = all
          if (input.grep) {
            let re: RegExp
            try {
              re = new RegExp(input.grep)
            } catch {
              return err([`Invalid grep regex: ${input.grep}`])
            }
            subset = all.filter((l) => re.test(l))
          } else if (input.tail) {
            subset = all.slice(-(input.tail as number))
          }
          const truncated = subset.length > maxLines
          const shown = subset.slice(-maxLines)
          return ok([
            `Job ${rec.id} [${rec.status}]  log lines in tail window: ${all.length}`,
            `returning ${shown.length}${truncated ? ` of ${subset.length} (truncated; use tail= or grep= to narrow)` : ""}`,
            ...(shown.length ? ["", ...shown.map((l) => `  | ${l}`)] : ["(no matching output)"]),
          ])
        })
      },
    }

    const bgSend = {
      name: "bg_send",
      description:
        "Send input to a running session's tmux pane (ssh prompts, pagers, confirmations, REPLs). " +
        "mode=text (default) sends the text followed by Enter; mode=keys sends tmux key names (Enter, Escape, C-c, Up...) without extra text.",
      input: {
        type: "object",
        properties: {
          id: refProp,
          input: {
            type: "string",
            description: "Text to type, or tmux key name(s) when mode=keys (e.g. 'C-c' or 'Enter').",
          },
          mode: {
            type: "string",
            enum: ["text", "keys"],
            default: "text",
            description: "text = literal text + Enter; keys = tmux key names, no Enter appended.",
          },
        },
        required: ["id", "input"],
        additionalProperties: false,
      },
      async execute(input: any) {
        return guarded(async () => {
          const rec = reconcile(resolve(input.id))
          if (!hasSession(rec.tmuxSession)) {
            return err([`Job ${rec.id} has no live tmux session (status: ${rec.status}).`])
          }
          const mode = (input.mode as string | undefined) ?? "text"
          const target = `${windowTarget(rec.tmuxSession)}.0`
          if (mode === "text") {
            if ((input.input as string).length > 0) tmux(["send-keys", "-t", target, "-l", input.input])
            tmux(["send-keys", "-t", target, "Enter"])
          } else {
            const keys = (input.input as string).trim().split(/\s+/)
            if (keys.length === 0 || keys[0] === "") return err(["input is required when mode=keys."])
            tmux(["send-keys", "-t", target, ...keys])
          }
          await sleep(400)
          const lines = recentLines(rec, 10)
          return ok([
            `Sent to ${rec.tmuxSession}: ${mode === "text" ? JSON.stringify(input.input) + " + Enter" : input.input}`,
            ...(lines.length ? ["", "recent output:", ...lines.map((l) => `  | ${l}`)] : ["(no output yet)"]),
            `NEXT STEP: bg_output {id} to read the response; repeat bg_send for further interaction.`,
          ])
        })
      },
    }

    const bgKill = {
      name: "bg_kill",
      description:
        "Kill a background job's tmux session and mark it killed (or finished/failed if it already exited). " +
        "purge=true also deletes the job's record and log files.",
      input: {
        type: "object",
        properties: {
          id: refProp,
          purge: { type: "boolean", default: false, description: "Also delete the job record and log." },
        },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any) {
        return guarded(async () => {
          const rec = reconcile(resolve(input.id))
          const killed = tmuxOk(["kill-session", "-t", rec.tmuxSession])
          if (rec.status === "running") {
            const ec = readExitCode(rec.id)
            rec.status = ec !== null ? (ec === 0 ? "finished" : "failed") : "killed"
            if (ec !== null) rec.exitCode = ec
            rec.endedAt = nowIso()
            writeRecord(rec)
          }
          const purge = (input.purge as boolean | undefined) ?? false
          if (purge) {
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
    }

    const bgList = {
      name: "bg_list",
      description:
        "List background jobs: status, kind, id/name, runtime, exit code, tmux session name. " +
        "Default shows running jobs plus those finished in the last 24h; all=true shows every stored job.",
      input: {
        type: "object",
        properties: {
          all: {
            type: "boolean",
            default: false,
            description: "Include all stored jobs, not just active/recent ones.",
          },
        },
        additionalProperties: false,
      },
      async execute(input: any) {
        return guarded(async () => {
          ensureDir()
          const all = (input.all as boolean | undefined) ?? false
          const recs = listRecords().map(reconcile)
          const shown = all
            ? recs
            : recs.filter((r) => r.status === "running" || Date.parse(r.endedAt ?? r.createdAt) > Date.now() - RECENT_MS)
          shown.sort((a, b) => {
            const ar = a.status === "running" ? 0 : 1
            const br = b.status === "running" ? 0 : 1
            if (ar !== br) return ar - br
            return Date.parse(b.endedAt ?? b.createdAt) - Date.parse(a.endedAt ?? a.createdAt)
          })
          if (shown.length === 0) {
            return info([`No background jobs${all ? "" : " in the last 24h (try all=true)"}.`])
          }
          const lines = shown.map((r) => {
            const name = r.name ? `  name=${r.name}` : ""
            const ec = r.exitCode !== undefined ? `  exit=${r.exitCode}` : ""
            const cmd = r.command.length > 60 ? `${r.command.slice(0, 57)}...` : r.command
            return `${r.status.padEnd(11)} ${r.kind.padEnd(8)} ${r.id}${name}${ec}  ${formatRuntime(r)}  tmux=${r.tmuxSession}  ${cmd}`
          })
          return ok([
            `${shown.length} job(s)${all ? "" : " (running first, then recent)"}:`,
            ...lines,
            `NEXT STEP: bg_status {id} for detail; tmux attach -t <session> to watch live.`,
          ])
        })
      },
    }

    await ctx.tool.transform((editor) => {
      editor.add(bgStart)
      editor.add(bgStatus)
      editor.add(bgOutput)
      editor.add(bgSend)
      editor.add(bgKill)
      editor.add(bgList)
    })
  },
})
