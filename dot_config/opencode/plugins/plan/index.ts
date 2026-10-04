import { Plugin } from "@opencode/plugin"
import { createHash, randomBytes } from "node:crypto"
import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const PLUGIN_NAME = "plan-plugin"
const STORAGE_ROOT = join(homedir(), ".local", "share", "opencode", "plans")
const STATUSES = ["pending", "in_progress", "done"] as const
const PLAN_TYPES = ["feature", "bug", "refactor", "docs"] as const

type TaskStatus = (typeof STATUSES)[number]
type PlanStatus = TaskStatus

type Task = { content: string; status: TaskStatus }
type Phase = { name: string; tasks: Task[] }

type Metadata = {
  title: string
  type: (typeof PLAN_TYPES)[number]
  description: string
  created: string
  updated: string
}

type Spec = {
  description: string
  functionals: string[]
  nonFunctionals: string[]
  acceptanceCriterias: string[]
  outOfScope: string[]
}

type Implementation = { description: string; phases: Phase[] }

type Plan = {
  id: string
  status: PlanStatus
  metadata: Metadata
  specifications: Spec
  implementation: Implementation
}

type Dir = { root: string; dir: string; status: PlanStatus }
type FlatTask = { task: Task; phase: string; index: string }

function planRoot(key: string): string {
  const hash = createHash("sha256").update(key || process.cwd()).digest("hex").slice(0, 16)
  return join(STORAGE_ROOT, hash)
}

const PLAN_PROMPT = `You are the Plan agent. Design structured, phased implementation plans with the plan_* tools.

## Workflow
1. Assess the request for intent, risks, and gaps. If ambiguous, use the question tool to clarify.
2. Call plan_list (no filters, then narrow) to check for related plans.
   - Related plan exists: ask the user whether to extend it (plan_update) or create a new one.
   - Extending: plan_read (summary first, deeper views only if needed).
   - Do NOT execute tasks — that is the build agent's job.
3. Explore the codebase (task tool with the explore subagent) to ground the plan in real paths and patterns.
4. Call plan_create with: metadata, specifications, and a phased implementation.
   - Tasks must be atomic, ordered, and written as verifiable actions.
   - The final phase must cover verification and testing.

## After creation
- Tell the user the plan id and that it is stored under ~/.local/share/opencode/plans/<project-id>/.
- Tell the user to switch to the build agent to execute it, one task at a time.`

const BUILD_PROMPT = `You are the Build agent. Execute the active plan with the plan_* tools, one task at a time.

## Workflow
1. If a plan id is already known in this conversation, use it. Otherwise call plan_list and pick the active plan (pending or in_progress); if several match the user's intent, ask which one.
2. Call plan_next to get the current task. Work on exactly that task.
3. Before working: plan_update taskUpdates [{task: "<id>", status: "in_progress"}]. Implement, test, verify against the task text.
4. When done: plan_update taskUpdates [{task: "<id>", status: "done"}]. Then call plan_next again.
5. When plan_next reports all tasks done: run final verification against the acceptance criteria (plan_read view=spec), then ask the user for approval before archiving with plan_update {id, status: "done"}.

## Rules
- Reference tasks by id (e.g. "2.1") as returned by plan_next / plan_read view=plan.
- Keep the user informed: after each task, report briefly what changed.
- If a task turns out to be wrong or too large, stop and ask the user; suggest handing back to the plan agent.`

function renderPlanMd(plan: Plan): string {
  const lines: string[] = [
    `# ${plan.metadata.title}`,
    ``,
    `> id: \`${plan.id}\` · status: **${plan.status}** · type: ${plan.metadata.type}`,
    `> created: ${plan.metadata.created} · updated: ${plan.metadata.updated}`,
    ``,
    plan.metadata.description,
    ``,
    `## Specifications`,
    ``,
    plan.specifications.description,
    ``,
    `### Functional requirements`,
    ...plan.specifications.functionals.map((f) => `- ${f}`),
    ``,
    `### Non-functional requirements`,
    ...plan.specifications.nonFunctionals.map((f) => `- ${f}`),
    ``,
    `### Acceptance criteria`,
    ...plan.specifications.acceptanceCriterias.map((f) => `- [ ] ${f}`),
    ``,
    `### Out of scope`,
    ...plan.specifications.outOfScope.map((f) => `- ${f}`),
    ``,
    `## Implementation`,
    ``,
    plan.implementation.description,
    ``,
  ]
  for (const [pi, phase] of plan.implementation.phases.entries()) {
    lines.push(`### Phase ${pi + 1}: ${phase.name}`, ``)
    for (const [ti, task] of phase.tasks.entries()) {
      const mark = task.status === "done" ? "x" : " "
      lines.push(`- [${mark}] \`${pi + 1}.${ti + 1}\` **[${task.status}]** ${task.content}`)
    }
    lines.push(``)
  }
  return lines.join("\n")
}

function writePlan(d: Dir, plan: Plan) {
  plan.metadata.updated = new Date().toISOString()
  plan.status = d.status
  writeFileSync(join(d.dir, "metadata.json"), JSON.stringify(plan.metadata, null, 2))
  writeFileSync(join(d.dir, "specifications.json"), JSON.stringify(plan.specifications, null, 2))
  writeFileSync(join(d.dir, "implementation.json"), JSON.stringify(plan.implementation, null, 2))
  writeFileSync(join(d.dir, "plan.md"), renderPlanMd(plan))
}

function readPlan(d: Dir, id: string): Plan | null {
  try {
    const metadata = JSON.parse(readFileSync(join(d.dir, "metadata.json"), "utf8"))
    const specifications = JSON.parse(readFileSync(join(d.dir, "specifications.json"), "utf8"))
    const implementation = JSON.parse(readFileSync(join(d.dir, "implementation.json"), "utf8"))
    return { id, status: d.status, metadata, specifications, implementation }
  } catch {
    return null
  }
}

function findPlan(root: string, id: string): { d: Dir; plan: Plan } | null {
  for (const status of STATUSES) {
    const dir = join(root, status, id)
    if (!existsSync(dir)) continue
    const d: Dir = { root, dir, status }
    const plan = readPlan(d, id)
    if (plan) return { d, plan }
  }
  return null
}

function listPlans(root: string): { d: Dir; plan: Plan }[] {
  const out: { d: Dir; plan: Plan }[] = []
  if (!existsSync(root)) return out
  for (const status of STATUSES) {
    const sdir = join(root, status)
    if (!existsSync(sdir)) continue
    for (const entry of readdirSync(sdir, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue
      const d: Dir = { root, dir: join(sdir, entry.name), status }
      const plan = readPlan(d, entry.name)
      if (plan) out.push({ d, plan })
    }
  }
  return out
}

function uniqueId(root: string, title: string): string {
  const slug =
    title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/^_+|_+$/g, "")
      .slice(0, 40) || "plan"
  for (let i = 0; i < 5; i++) {
    const id = `${slug}_${randomBytes(3).toString("hex")}`
    if (!STATUSES.some((s) => existsSync(join(root, s, id)))) return id
  }
  return `${slug}_${Date.now()}`
}

function progress(plan: Plan) {
  const tasks = plan.implementation.phases.flatMap((p) => p.tasks)
  return {
    total: tasks.length,
    done: tasks.filter((t) => t.status === "done").length,
    inProgress: tasks.filter((t) => t.status === "in_progress").length,
  }
}

function flattenTasks(plan: Plan): FlatTask[] {
  return plan.implementation.phases.flatMap((phase, pi) =>
    phase.tasks.map((task, ti) => ({ task, phase: phase.name, index: `${pi + 1}.${ti + 1}` })),
  )
}

const wrap = (tag: string, lines: string[]) => [`<${tag}>`, ...lines, `</${tag}>`].join("\n")
const ok = (lines: string[]) => wrap("tool-success", lines)
const err = (lines: string[]) => wrap("tool-error", lines)
const info = (lines: string[]) => wrap("tool-info", lines)

export default Plugin.define({
  id: "plan",
  async setup(ctx) {
    console.log(`[${PLUGIN_NAME}] initialized`)

    async function sessionKey(sessionID: string): Promise<string> {
      try {
        const session = await ctx.session.get({ sessionID })
        const dir = (session as unknown as { location?: { directory?: unknown } })?.location?.directory
        if (typeof dir === "string" && dir.length > 0) return dir
      } catch {}
      return process.cwd()
    }

    async function rootFor(sessionID: string): Promise<string> {
      return planRoot(await sessionKey(sessionID))
    }

    const idProp = { type: "string", description: "Plan id (from plan_create or plan_list)" }

    const planCreate = {
      name: "plan_create",
      description:
        "Create a new structured implementation plan for this project. Plans live outside the repo, under ~/.local/share/opencode/plans/<project-hash>/. After reviewing the plan with the user, agents execute it task-by-task with plan_next and plan_update.",
      input: {
        type: "object",
        properties: {
          metadata: {
            type: "object",
            properties: {
              title: { type: "string", description: "Short human-readable plan title" },
              type: { type: "string", enum: [...PLAN_TYPES] },
              description: { type: "string", description: "One-paragraph summary of purpose and scope" },
            },
            required: ["title", "type", "description"],
            additionalProperties: false,
          },
          specifications: {
            type: "object",
            properties: {
              description: { type: "string", description: "Detailed description of what needs to be done" },
              functionals: {
                type: "array",
                items: { type: "string" },
                minItems: 1,
                description: "Functional requirements (user-facing behavior)",
              },
              nonFunctionals: {
                type: "array",
                items: { type: "string" },
                minItems: 1,
                description: "Performance, security, style, ...",
              },
              acceptanceCriterias: {
                type: "array",
                items: { type: "string" },
                minItems: 1,
                description: "Testable outcomes",
              },
              outOfScope: {
                type: "array",
                items: { type: "string" },
                description: "Explicitly excluded items",
              },
            },
            required: ["description", "functionals", "nonFunctionals", "acceptanceCriterias", "outOfScope"],
            additionalProperties: false,
          },
          implementation: {
            type: "object",
            properties: {
              description: { type: "string", description: "Overall implementation approach" },
              phases: {
                type: "array",
                minItems: 1,
                items: {
                  type: "object",
                  properties: {
                    name: { type: "string", description: "Phase name (e.g. 'Phase 1: schema')" },
                    tasks: {
                      type: "array",
                      minItems: 1,
                      items: {
                        type: "object",
                        properties: {
                          content: {
                            type: "string",
                            description: "One atomic, verifiable action; exact text matters",
                          },
                          status: { type: "string", enum: [...STATUSES], default: "pending" },
                        },
                        required: ["content"],
                        additionalProperties: false,
                      },
                    },
                  },
                  required: ["name", "tasks"],
                  additionalProperties: false,
                },
              },
            },
            required: ["description", "phases"],
            additionalProperties: false,
          },
        },
        required: ["metadata", "specifications", "implementation"],
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        const root = await rootFor(toolCtx.sessionID)
        const implementation = input.implementation as Implementation
        for (const phase of implementation.phases) {
          for (const task of phase.tasks) {
            if (task.status !== "in_progress" && task.status !== "done") task.status = "pending"
          }
        }
        const metadata = input.metadata as { title: string; type: (typeof PLAN_TYPES)[number]; description: string }
        const id = uniqueId(root, metadata.title)
        const dir = join(root, "pending", id)
        mkdirSync(dir, { recursive: true })
        const now = new Date().toISOString()
        const plan: Plan = {
          id,
          status: "pending",
          metadata: { ...metadata, created: now, updated: now },
          specifications: input.specifications as Spec,
          implementation,
        }
        writePlan({ root, dir, status: "pending" }, plan)
        const p = progress(plan)
        return {
          content: ok([
            `Plan created: ${id}`,
            `Stored in: ${dir}`,
            `Phases: ${plan.implementation.phases.length} · tasks: ${p.total}`,
            `First task: 1.1 — ${plan.implementation.phases[0].tasks[0].content}`,
            `NEXT STEP: Review the plan with the user. To execute, call plan_next before each task and track progress with plan_update taskUpdates. Archive with plan_update {id, status: "done"} once everything is done.`,
          ]),
        }
      },
    }

    const planList = {
      name: "plan_list",
      description: "List plans for this project, filtered by status and/or type. Lightweight.",
      input: {
        type: "object",
        properties: {
          status: { type: "string", enum: [...STATUSES] },
          type: { type: "string", enum: [...PLAN_TYPES] },
        },
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        const root = await rootFor(toolCtx.sessionID)
        const status = input.status as PlanStatus | undefined
        const type = input.type as (typeof PLAN_TYPES)[number] | undefined
        const rows = listPlans(root)
          .filter(({ plan }) => (!status || plan.status === status) && (!type || plan.metadata.type === type))
          .map(({ plan }) => {
            const p = progress(plan)
            return `${plan.status.padEnd(11)} ${plan.metadata.type.padEnd(9)} ${plan.id}  "${plan.metadata.title}" — ${p.done}/${p.total} tasks done`
          })
        if (rows.length === 0) {
          return { content: info([`No plans match (status: ${status ?? "any"}, type: ${type ?? "any"}).`]) }
        }
        return { content: ok([`${rows.length} plan(s):`, ...rows, `NEXT STEP: Use plan_read <id> view=summary for details.`]) }
      },
    }

    const planRead = {
      name: "plan_read",
      description:
        "Read a plan with a selective view to limit context: 'summary' (metadata + progress), 'spec' (requirements), 'plan' (task checklist with ids), or 'full' (everything, JSON).",
      input: {
        type: "object",
        properties: {
          id: idProp,
          view: { type: "string", enum: ["summary", "spec", "plan", "full"], default: "summary" },
        },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        const view = (input.view as string | undefined) ?? "summary"
        const found = findPlan(await rootFor(toolCtx.sessionID), input.id)
        if (!found) return { content: err([`Plan not found: ${input.id}.`, `NEXT STEP: Call plan_list to see available plans.`]) }
        const { plan } = found
        if (view === "full") {
          return { content: JSON.stringify(plan, null, 2) }
        }
        const p = progress(plan)
        const head = [
          `id: ${plan.id}`,
          `status: ${plan.status} · type: ${plan.metadata.type}`,
          `title: ${plan.metadata.title}`,
          `description: ${plan.metadata.description}`,
          `progress: ${p.done}/${p.total} tasks done, ${p.inProgress} in progress`,
        ]
        if (view === "summary") return { content: ok(head) }
        if (view === "spec") {
          return {
            content: ok([
              ...head,
              ``,
              `Overview: ${plan.specifications.description}`,
              `Functional requirements:`,
              ...plan.specifications.functionals.map((f) => `- ${f}`),
              `Non-functional requirements:`,
              ...plan.specifications.nonFunctionals.map((f) => `- ${f}`),
              `Acceptance criteria:`,
              ...plan.specifications.acceptanceCriterias.map((f) => `- ${f}`),
              `Out of scope:`,
              ...plan.specifications.outOfScope.map((f) => `- ${f}`),
            ]),
          }
        }
        return {
          content: ok([
            ...head,
            ``,
            `Implementation: ${plan.implementation.description}`,
            ...plan.implementation.phases.flatMap((phase, pi) => [
              ``,
              `Phase ${pi + 1}: ${phase.name}`,
              ...phase.tasks.map((t, ti) => `- \`${pi + 1}.${ti + 1}\` [${t.status}] ${t.content}`),
            ]),
            `NEXT STEP: Use task ids (e.g. 2.1) with plan_update and plan_next.`,
          ]),
        }
      },
    }

    const planUpdate = {
      name: "plan_update",
      description:
        "Update a plan: change its status (pending → in_progress → done) and/or batch-update task statuses. Reference tasks by id (e.g. '1.2') or by exact content text.",
      input: {
        type: "object",
        properties: {
          id: idProp,
          status: { type: "string", enum: [...STATUSES] },
          taskUpdates: {
            type: "array",
            items: {
              type: "object",
              properties: {
                task: { type: "string", description: "Task id like '2.1', or the exact task content" },
                status: { type: "string", enum: [...STATUSES] },
              },
              required: ["task", "status"],
              additionalProperties: false,
            },
          },
        },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        const root = await rootFor(toolCtx.sessionID)
        const found = findPlan(root, input.id)
        if (!found) return { content: err([`Plan not found: ${input.id}.`, `NEXT STEP: Call plan_list.`]) }
        const { d, plan } = found
        const updated: string[] = []
        const unresolved: string[] = []
        const taskUpdates = input.taskUpdates as { task: string; status: TaskStatus }[] | undefined

        if (taskUpdates?.length) {
          const flat = flattenTasks(plan)
          const hit = new Set<number>()
          for (const upd of taskUpdates) {
            const i = flat.findIndex(({ task, index }, fi) => !hit.has(fi) && (index === upd.task || task.content === upd.task))
            if (i === -1) {
              unresolved.push(upd.task)
              continue
            }
            hit.add(i)
            flat[i].task.status = upd.status
            updated.push(`${flat[i].index} ${flat[i].task.content} → ${upd.status}`)
          }
          if (unresolved.length > 0) {
            return {
              content: err([
                `Could not resolve task reference(s): ${unresolved.join(", ")}.`,
                `No changes were saved.`,
                `NEXT STEP: Call plan_read view=plan and use exact ids or exact task text.`,
              ]),
            }
          }
          writePlan(d, plan)
        }

        const status = input.status as PlanStatus | undefined
        if (status && status !== d.status) {
          const newDir = join(root, status, plan.id)
          mkdirSync(join(root, status), { recursive: true })
          renameSync(d.dir, newDir)
          writePlan({ root, dir: newDir, status }, plan)
          return {
            content: ok([
              `Plan ${plan.id}: ${d.status} → ${status}`,
              ...(updated.length ? [``, `Tasks:`, ...updated.map((u) => `- ${u}`)] : []),
              `NEXT STEP: Call plan_next for the next actionable task.`,
            ]),
          }
        }

        return {
          content: ok([
            `Plan ${plan.id} updated`,
            ...(updated.length ? [`Tasks:`, ...updated.map((u) => `- ${u}`)] : [`No changes requested.`]),
            `NEXT STEP: Call plan_next for the next actionable task.`,
          ]),
        }
      },
    }

    const planNext = {
      name: "plan_next",
      description:
        "Get the next actionable task for this plan: the in_progress task if any, else the first pending task. Start each work step with this instead of re-reading the whole plan.",
      input: {
        type: "object",
        properties: { id: idProp },
        required: ["id"],
        additionalProperties: false,
      },
      async execute(input: any, toolCtx: any) {
        const found = findPlan(await rootFor(toolCtx.sessionID), input.id)
        if (!found) return { content: err([`Plan not found: ${input.id}.`, `NEXT STEP: Call plan_list.`]) }
        const { plan } = found
        const flat = flattenTasks(plan)
        const current = flat.find(({ task }) => task.status === "in_progress")
        if (current) {
          return {
            content: ok([
              `Plan: ${plan.id} (${plan.status})`,
              `Resume task (in_progress):`,
              `  id: ${current.index}`,
              `  phase: ${current.phase}`,
              `  task: ${current.task.content}`,
              `NEXT STEP: Do the work, then plan_update taskUpdates [{task: "${current.index}", status: "done"}] and call plan_next again.`,
            ]),
          }
        }
        const next = flat.find(({ task }) => task.status === "pending")
        if (next) {
          return {
            content: ok([
              `Plan: ${plan.id} (${plan.status})`,
              `Next task (pending):`,
              `  id: ${next.index}`,
              `  phase: ${next.phase}`,
              `  task: ${next.task.content}`,
              `NEXT STEP: plan_update taskUpdates [{task: "${next.index}", status: "in_progress"}], do the work, mark it done, then call plan_next again.`,
            ]),
          }
        }
        return {
          content: info([
            `All ${flat.length} tasks are done for plan ${plan.id}.`,
            `NEXT STEP: Verify the acceptance criteria (plan_read view=spec), then ask the user to approve archiving via plan_update {id, status: "done"}. Plan approval stays with the user.`,
          ]),
        }
      },
    }

    await ctx.agent.transform((editor) => {
      const prompts: Record<string, string> = { plan: PLAN_PROMPT, build: BUILD_PROMPT }
      for (const [id, prompt] of Object.entries(prompts)) {
        const agent = editor.get(id)
        if (agent && !agent.system) {
          editor.update(id, (a) => {
            a.system = prompt
          })
        }
      }
    })

    await ctx.tool.transform((editor) => {
      editor.add(planCreate)
      editor.add(planList)
      editor.add(planRead)
      editor.add(planUpdate)
      editor.add(planNext)
    })
  },
})
