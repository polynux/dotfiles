# Global agent instructions

For code search and refactors, use ast-grep (load the `ast-grep` skill) instead of grep/rg/sed.

## Model budget for delegated work

Applies to every project. When you launch a T3 thread, delegate a task, or start any other agent that does execution work (planning, coding, refactors, UI checks, verification), pick its model from these tiers. Don't let it inherit your own model.

**Tier 1, gated on account limits.** Use these first while their account has headroom (see "Checking limits" below).

| Model | Provider instance | Gate | Use for |
|---|---|---|---|
| `gpt-6-luna` | `codex` | Codex limit under 80% | Best quality in the 2026-10-16 benchmark, and fast. Multi-file work, debugging, judging, verification. |
| `claude-haiku-5-5` | `claudeAgent` | Claude session under 70% **and** week under 80% | Fastest, clean minimal diffs. Well-scoped tasks, checks, verification. It shares the Claude subscription with you (the orchestrator), so the gate also protects your own budget. |

**Tier 2, no gate.** Use when both Tier 1 accounts are over their gate, or to spread load.

| Model | Provider instance | Use for |
|---|---|---|
| `opencode-go/deepseek-v4.1-flash` | `opencode` | Correct and quick (40/40 tests, about Haiku's quality). Small-to-medium coding tasks. |
| `opencode-go/muse-spark-1.3-contributor` | `opencode` | Autonomous multi-file work, browser and UI work, CLI-heavy agent work. Weak spots: over-engineers small diffs and creeps in scope, so the brief must say "minimal diff, no new abstractions". |

### Checking limits

Check right before picking a Tier 1 model, once per batch of launches:

- **Claude:** `claude -p "/usage"` prints "Current session: N% used" and "Current week (all models): N% used".
- **Codex:** the newest session log holds the last snapshot: `jq -r 'select(.payload.rate_limits?) | .payload.rate_limits.primary.used_percent' "$(ls -t ~/.codex/sessions/*/*/*/*.jsonl | head -1)" | tail -1` (Go plan, 30-day window). With no recent session, treat Codex as available.

When a gate blocks a Tier 1 model, say so in one line ("Claude week at 85%, using DeepSeek").

### Rules

- **Verification** uses a different model than the one that did the work.
- **Use only the four models above** unless the user asks. In particular `opencode-go/mimo-v2.6-flash` (user decision, 2026-10-15) and `glm-5.3-flash` (slowest in the benchmark, and it stalled on opencode-go) stay out.
- **Larger Claude models (Opus, Sonnet, …)** are for the orchestrator's own review and judgement, not for execution threads, unless the user says otherwise.
- **Every opencode brief must include:** "Run commands in the foreground with long timeouts; never end your turn waiting for a background notification." Otherwise these agents background slow commands and end their turn "waiting to be resumed", and T3 never resumes them. If a run ends that way anyway, nudge it with `t3_thread_send`.
- **If a provider's limits run out mid-task:** move to the next model in tier order, and tell the user.
- **Parallel tasks:** give each its own git worktree, and distinct ports if they run dev servers.
- **After launching a thread:** wait for it (`t3_thread_wait`, looping on timeout), then review its result before replying to the user.
