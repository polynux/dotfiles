# Global agent instructions

## Model budget for delegated work

Applies to every project. When you launch a T3 thread, delegate a task, or start any other agent that does execution work (planning, coding, refactors, UI checks, verification), pick its model from this table. Don't let it inherit your own model. Use only these two models for delegated work.

| Model | Provider instance | Use for |
|---|---|---|
| `opencode-go/muse-spark-1.3-contributor` | `opencode` | **Default.** Autonomous multi-file work, debugging without hand-holding, tracing across files, browser and UI work, practical plans, CLI-heavy agent work. Weak spots: over-engineers small diffs and creeps in scope, so the brief must say "minimal diff, no new abstractions". |
| `claude-haiku-5-5` | `claudeAgent` | Second choice: independent verification of another thread's work (a different model than the one that did it), well-scoped checks and small tasks. |

- **Don't use** `opencode-go/mimo-v2.6-flash` (user decision, 2026-10-15), nor the other opencode-go models (`deepseek-v4.1-flash`, `glm-5.3-flash`), unless the user asks.
- **Larger Claude models (Opus, Sonnet, …)** are for the orchestrator's own review and judgement, not for execution threads, unless the user says otherwise.
- **Every opencode brief must include:** "Run commands in the foreground with long timeouts; never end your turn waiting for a background notification." Otherwise these agents background slow commands and end their turn "waiting to be resumed", and T3 never resumes them. If a run ends that way anyway, nudge it with `t3_thread_send`.
- **If opencode-go limits run out:** fall back to `claude-haiku-5-5`, and tell the user.
- **Parallel tasks:** give each its own git worktree, and distinct ports if they run dev servers.
- **After launching a thread:** wait for it (`t3_thread_wait`, looping on timeout), then review its result before replying to the user.
