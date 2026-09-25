---
name: plane-issues
description: Plane.so issue tracking workflow. Use ONLY when the complete Plane MCP inventory required by this skill is available. If Plane tools are unavailable or incomplete, do nothing and stay quiet. When available, track plans, bugs, explicit issue requests, state transitions, evidence, and closure without duplicates or sensitive data.
---

# Plane issue tracking

Plane is the source of truth for issues. When its tools are available, tracking
work there is not optional — it is part of finishing the work.

## Source and drift control

`~/.config/opencode/skills/plane-issues/SKILL.md` is the canonical runtime copy
of this skill. The matching `~/.agents/skills/plane-issues/SKILL.md` path must
be a symlink to this file; do not maintain a second regular-file copy.

Check the relationship without modifying it:

```bash
test -L "$HOME/.agents/skills/plane-issues/SKILL.md" &&
test "$(readlink -f "$HOME/.agents/skills/plane-issues/SKILL.md")" = \
  "$(readlink -f "$HOME/.config/opencode/skills/plane-issues/SKILL.md")"
```

The chezmoi source for the OpenCode copy is maintained separately by the
user's dotfile workflow.

## Activation

These rules apply ONLY when the complete Plane MCP inventory below is available
in this session. If Plane tools are unavailable or incomplete, do nothing and
stay quiet. Do not enable Plane, inspect credentials, infer API access, or
recreate Plane calls through another integration.

Required inventory:

| Tool family | Required operations |
|---|---|
| `project` | `list`, `create` |
| `workitem` | `retrieve_by_identifier`, `search` or `list`, `create`, `update` |
| `workitem_comment` | `create` |
| `workitem_relation` | `create` |
| `workitem_type` | `resolve` |
| `label` | `list`, `create` |
| `state` | `list` |
| PQL support | `get_pql_reference` when PQL syntax is unclear |

Every operation referenced by this skill must be available before Plane work
begins.

These rules apply to:

- **Plans**: planning a feature, roadmap, refactor, or any multi-step design. Every actionable task in the plan becomes a Plane work item.
- **Bugs**: discovered errors, failing tests, reproduced defects. Each gets an issue immediately.
- **Explicit requests**: "file this", "track it", "log an issue", "open a ticket".
- **Tracked work**: resuming, implementing, verifying, deploying, or closing an
  existing work item.

## Redaction and data handling

Plane titles, descriptions, comments, evidence, and final responses must use
the minimum information needed to track and verify the work.

Never copy or disclose:

- API keys, access tokens, passwords, cookies, session values, private keys,
  webhook secrets, environment values, or credential-file contents.
- Complete customer messages, chat transcripts, private contact details,
  order identifiers, payment data, account identifiers, or other personal data.
- Raw database rows, dumps, exports, query results containing customer data, or
  database credentials.
- Raw production logs, sensitive stack traces, request bodies, authorization
  headers, session identifiers, token-bearing URLs, or unfiltered screenshots.

Use an anonymized summary containing only the symptom, relevant category,
necessary date or timestamp, environment, and a non-sensitive reference.
Replace values with `[REDACTED]` in commands, output, diffs, screenshots,
attachments, comments, and final responses. If sensitive data appears, stop
sharing it, redact it, and record only that exposure occurred.

For customer-originated requests, record minimal provenance such as the date or
non-sensitive message reference; never paste the original message. For database
or production investigations, record purpose, scope, counts, status, and result
category, never raw values or unfiltered logs.

## Project resolution — never guess

Resolve the target Plane project before any tool call that takes `project_id`,
in this order:

1. **AGENTS.md first**: read `AGENTS.md` in the project root. If it contains a
   line `Plane project: <name>`, that is the project. (Users maintain it via the
   `/plane-project` command.)
2. **Match by name**: call `project` `list` and match the current repo or work
   context against project names and identifiers. Case-insensitive; a unique
   match wins.
3. **Ask**: no match, or several candidates — ask the user once, then remember
   the choice for the rest of the session. Do not re-ask.

If the workspace has no matching project, say so and ask whether to create one
(`project` `create`) before filing anything.

## Update over create — no duplicates

Before creating any work item:

1. Explicit reference given (e.g. `AUTH-42`)? → `workitem` `retrieve_by_identifier`.
2. Otherwise search inside the resolved project: `workitem` `search` (or
   `workitem` `list` with PQL, e.g. `pql='name ~ "login"'`). Call
   `get_pql_reference` if syntax is unclear.
3. **Match found** → `workitem` `update` (description, state, priority as
   appropriate) and `workitem_comment` `create` summarizing the new finding.
   Never create a near-duplicate.
4. **No match** → create.

## Plans → issues

When a plan is agreed (or plan mode completes):

1. Resolve the project (above).
2. **Propose once**: list the issues you intend to create — titles, parent/epic
   structure, labels — and ask "create these N issues in <project>?".
3. After confirmation, create them all: parents/epics first (`workitem_type`
   `resolve` with `name="Epic"` for the `type_id` if epic structure is needed),
   children with `parent` set; cross-links via `workitem_relation` `create`.
4. Each `description_html` carries the relevant plan context: goal, scope,
   acceptance criteria, affected files/modules.
5. Add a `workitem_comment` `create` on each referencing the plan or session
   that produced it.
6. Report the created identifiers (e.g. `AUTH-43`) back to the user.
7. Link every item to the source plan and retain its exact identifier.
8. Add the plan link, acceptance criteria, affected scope, and expected
   verification evidence to the item's comment.

## Bugs → issues

1. Resolve the project. Search for an existing matching item first; a single bug
   does not require bulk confirmation, but it still follows the no-duplicates
   workflow above.
2. If no matching item exists, `workitem` `create` with:
   - title: short symptom, not the diagnosis ("500 on POST /login", not "broken");
   - description_html: repro steps, expected vs actual, error output, affected
     code path (file:line), environment notes;
    - label `bug` — check with `label` `list` first; if it is missing, confirm
      before using `label` `create`;
   - priority: set from severity when evident, otherwise leave default and say so.
3. When the bug is fixed: `workitem` `update` the state to Done and add a
   closing comment only after the Definition of Done is satisfied. Include the
   issue identifier, plan link or explicit non-applicability, fix summary,
   commit, deployment reference or explicit non-applicability, verification
   evidence, and known limitations.

## Required work-item record

Every actionable item must contain or link to:

- the exact issue identifier, such as `AUTH-42`;
- the relevant plan link, or `Plan: not applicable` with a reason;
- scope, acceptance criteria, affected files or systems, and environment;
- the implementation commit hash, once a change is committed;
- the deployment or release identifier when deployment applies, or
  `Deployment: not applicable` with a reason;
- verification evidence identifying checks and results;
- known limitations, skipped checks, blockers, and rollback or follow-up status.

Use the issue identifier in branch names, commits, deployment notes, and
verification records where those systems support it. Never invent identifiers,
links, hashes, deployment references, or verification results.

## State lifecycle

Projects carry states like Backlog, Todo, In Progress, Done, Canceled. Resolve
them once per session per project with `state` `list`; use state names when
talking to the user, state ids in `workitem` `update`. Transitions are
mandatory, not optional:

- **Created** plan items land in the project's default/backlog state. Do not
  pre-move items to In Progress "to be ready".
- **Starting work**: the turn you begin implementing an item (writing code for
  it), move it to "In Progress". Same turn, no exceptions.
- **Finished work**: only after the Definition of Done is satisfied, move it to
  "Done" and add the required evidence-bearing closing comment.
- **Dropped/superseded/won't do**: move to "Canceled" with a comment saying why.
  Do not delete items.
- **Blocked or paused**: keep In Progress and add a comment explaining the
  blocker; do not shuffle states to signal blocking.
- Never move an item backwards silently (Done → In Progress); if it must happen,
  explain it in a comment.
- If state names differ from these, pick the closest by group (backlog, started,
  completed, cancelled) and say which one you mapped to.

## Status hygiene

- Created plan items remain in the default/backlog state until work starts.
- Starting implementation moves the item to In Progress in the same turn.
- Verification failure, missing evidence, uncommitted changes, or an unresolved
  blocker prevents Done.
- Completed work gets Done in the same turn only after all closure evidence is
  recorded.
- When resuming tracked work, read the item's current state and comments first;
  if its state contradicts reality (e.g. "In Progress" but nothing started), fix
  it and note why in a comment.

## Guardrails

- `project_id` always comes from the resolution flow — never invented.
- No mass-creation outside the confirmed plan-conversion flow.
- Creating a Plane project, label, or state counts as a write: confirm first.
- Prefer one informative comment over rewriting descriptions wholesale on update.
- Never close an item with “commit if known”; record the applicable commit or
  explicit non-applicability before Done.
- Never place raw customer messages, database values, production logs, or
  credentials in Plane.
- If required evidence cannot be produced, keep the item open and state what is
  missing.

## Definition of Done

Move a work item to `Done` only when all applicable conditions are satisfied:

1. The exact Plane issue identifier is known and recorded.
2. Scope and acceptance criteria are current and unambiguous.
3. The relevant plan is linked, or non-applicability is recorded with a reason.
4. The implementation is complete within the agreed scope.
5. Applicable focused tests, broader tests, lint, builds, browser checks, and
   operational checks pass, with commands and results recorded.
6. Repository changes have been reviewed with `git diff` and committed; the
   commit hash is recorded. Uncommitted repository changes block Done.
7. Deployed changes include the target environment, deployment/release
   identifier, and result. Non-deployed changes explicitly say why deployment
   is not applicable.
8. Known failures, skipped checks, limitations, and rollback or follow-up work
   are resolved or tracked separately.
9. The closing comment includes issue, plan, implementation summary, commit,
   deployment, verification evidence, and limitations.
10. All evidence is redacted and contains no secrets, complete customer
    messages, raw database values, or unfiltered production logs.

If any applicable condition is missing, keep the item In Progress or in the
appropriate waiting state. A blocked or paused item remains In Progress with
the blocker and next decision recorded. A canceled item requires a comment
explaining why.
