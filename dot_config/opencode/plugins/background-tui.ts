import type { TuiPluginModule } from "@opencode-ai/plugin/tui"
import { existsSync, readdirSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const JOBS_DIR = join(homedir(), ".local", "state", "opencode", "bg-jobs")
const POLL_MS = 3000

type JobRecord = {
  id: string
  name?: string
  kind: string
  command: string
  status: string
  exitCode?: number
  createdAt: string
  endedAt?: string
}

const commandExcerpt = (cmd: string) => (cmd.length > 60 ? `${cmd.slice(0, 57)}...` : cmd)

function readRecords(): JobRecord[] {
  if (!existsSync(JOBS_DIR)) return []
  const out: JobRecord[] = []
  for (const e of readdirSync(JOBS_DIR, { withFileTypes: true })) {
    if (!e.isFile() || !e.name.endsWith(".json")) continue
    try {
      out.push(JSON.parse(readFileSync(join(JOBS_DIR, e.name), "utf8")) as JobRecord)
    } catch {}
  }
  return out
}

const TuiBackgroundPlugin: TuiPluginModule = {
  id: "background-tui",
  async tui(api) {
    const seen = new Set<string>(readRecords().filter((r) => r.status === "running").map((r) => r.id))

    const poll = () => {
      try {
        for (const rec of readRecords()) {
          if (rec.status !== "finished" && rec.status !== "failed") continue
          if (seen.has(rec.id)) continue
          seen.add(rec.id)
          if (rec.endedAt && Date.parse(rec.endedAt) < Date.now() - POLL_MS * 2) continue
          const label = rec.name ?? rec.id
          const okExit = rec.status === "finished"
          api.ui.toast({
            variant: okExit ? "success" : "error",
            title: `bg job ${label}`,
            message: `${okExit ? "finished" : `failed (exit ${rec.exitCode ?? "?"})`} — ${commandExcerpt(rec.command)}`,
            duration: 5000,
          })
        }
      } catch {}
    }

    const timer = setInterval(poll, POLL_MS)
    api.lifecycle.onDispose(() => clearInterval(timer))
  },
}

export default TuiBackgroundPlugin