# Freebuff CLI — API protocol notes

Findings from reverse-engineering the Freebuff CLI (v0.0.183, Codebuff-based
Bun binary) on 2026-09-22/23. Goal: reuse Freebuff's free models (GLM 5.3
Flash etc.) inside opencode or pi.

## Architecture

- npm package `freebuff` = launcher only. Downloads a Bun-compiled binary to
  `~/.config/manicode/freebuff` (yes, "manicode").
- The binary embeds `@codebuff/sdk` + Vercel AI SDK. Agent loop runs
  **locally**; model calls go to a server-side OpenAI-compatible gateway.

## Auth

- `~/.config/manicode/credentials.json` → `{ default: { id, name, email,
  authToken, fingerprintId, fingerprintHash } }` (0600).
- Every API call: `Authorization: Bearer <authToken>`. CLI also sends
  `x-freebuff-acting-user-id: <id>`.
- `CODEBUFF_API_KEY` env is read by the binary (header `x-codebuff-api-key`).
- Login flow: `POST /api/auth/cli/code {fingerprintId}` → browser →
  `GET /api/auth/cli/status?fingerprintId&fingerprintHash&expiresAt`.
  Logout: `POST /api/auth/cli/logout`.

## Base URL

- **`https://www.codebuff.com`** is what the binary uses (baked in).
  `freebuff.com` / `codebuff.com` apex serve HTML 404s on /api.
- Overridable at runtime: `NEXT_PUBLIC_CODEBUFF_APP_URL` or `CODEBUFF_APP_URL`
  — must be https, or http on loopback only.

## Key endpoints (all under https://www.codebuff.com)

- `GET  /api/v1/me?fields=email,...` — verify token. Works standalone. ✅
- `POST /api/v1/agent-runs` — body `{action:"START",agentId:"base",
  ancestorRunIds:[]}` → `{runId}` (UUID). Finish with `{action:"FINISH",
  runId,status:"completed",totalSteps,...}`. ✅
- `POST /api/v1/chat/completions` — OpenAI wire format + extra body field
  `codebuff_metadata: { run_id, client_id, cost_mode, freebuff_instance_id,
  freebuff_reasoning_effort }`. Streams SSE; `usage.cost` in response.
- Freebuff session (free tier):
  - `POST /api/v1/freebuff/session/admission` — acquire the 1-hour slot.
    Headers: `x-freebuff-model`, `x-freebuff-wallet-spend-limit`,
    `x-freebuff-first-tab-discount: 0|1`, `x-fb-timezone`.
    → `{status:"active",instanceId,expiresAt,freebucks,...}`. ✅
  - `GET  /api/v1/freebuff/session` — current state.
  - `DELETE /api/v1/freebuff/session` with `x-freebuff-instance-id` — end
    slot (refunds Freebucks). ⚠️ superseded the CLI's live session when we
    did this; only one active session per account.
- Local mirror of active session: `~/.config/manicode/freebuff-instance-owner.json`
  → `{instanceId, pid}`.
- `GET /api/v1/agents/codebuff/base/latest` — published agent templates.
  `base-free` is NOT in the DB; the CLI bundles it locally.

## Cost modes (decoded from binary)

```js
costMode map: { DEFAULT:"normal", LITE:"free" (freebuff) | "lite", MAX:"max", PLAN:"normal" }
extraCodebuffMetadata (freebuff): { freebuff_instance_id, freebuff_reasoning_effort }
```

- `cost_mode:"normal"` (or absent) → bills **paid Codebuff credits** → 402
  "Out of credits" (account has none).
- `cost_mode:"free"` + `freebuff_instance_id` → server validates
  agent/model combo → we got `403 free_mode_invalid_agent_model` with:
  - agent ids `base`, `base-free` (explicit run + inline SDK definition)
  - model `z-ai/glm-5.3-flash`
  The allowed combo is enforced **server-side** and not in the binary.

## @codebuff/sdk test (npm, v0.0.7+ / 0.10.7)

- Export is `CodebuffClient` (not `Codebuff`).
- `client.run()` requires `agent` (string or inline AgentDefinition).
  Passing none + `costMode:'free'` crashes (`agent.id` of undefined).
- Inline agent `{id:'base-free', model:'z-ai/glm-5.3-flash', toolNames:[...],
  instructionsPrompt,...}` + `costMode:'free'` runs the full local loop and
  reaches chat/completions — same 403 as curl. So the SDK reproduces the
  protocol correctly; only the server's free-mode allowlist is missing.
- The CLI is TUI-only (no headless prompt arg; only `login` subcommand) and
  refuses a second instance per HOME (instance-owner pid check).

## State / next steps

1. opencode.json has provider `freebuff` → baseURL
   `https://www.codebuff.com/api/v1`, apiKey `{file:~/.secrets/freebuff-token}`
   (extract with the node one-liner from credentials.json). Model
   `z-ai/glm-5.3-flash`. Will hit 402/403 until free-mode gating is solved.
2. Unsolved: exact free-mode agent/model combo (and any headers) the server
   expects. Ideas for next session:
   - Capture real CLI traffic (mitm over loopback proxy via
     `NEXT_PUBLIC_CODEBUFF_APP_URL=http://127.0.0.1:PORT` — works, but must
     run the CLI outside this harness to avoid the second-instance block;
     fake admission with live GET, never DELETE the real session).
   - Check response headers of chat/completions for hints (429 handler reads
     `retry-after`, error `free_mode_capacity_deferred` exists).
   - Try other models for the free combo (deepseek/deepseek-v4.1-flash,
     upstage/solar-pro4 — the "limited" tier models) with agent `base-free`.
3. Never `DELETE /api/v1/freebuff/session` while the user's CLI session is
   live — it kills their hour and their current conversation.
