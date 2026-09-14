---
name: plane-issues
description: Plane.so issue tracking workflow. Use ONLY when the plane MCP server's tools (project, workitem, workitem_comment, workitem_relation) are available in the current session. Trigger on planning, roadmaps, implementation plans, bug discovery, errors, failing tests, and any request to track, file, or log issues. Converts plans into Plane work items and bugs into labeled issues, deduplicates against existing items, and keeps statuses current.
---

# Plane issue tracking

Plane is the source of truth for issues. When its tools are available, tracking
work there is not optional — it is part of finishing the work.

## Activation

These rules apply ONLY when plane MCP tools are present in this session. If the
tools are absent, do nothing and stay quiet. If present, they apply to:

- **Plans**: planning a feature, roadmap, refactor, or any multi-step design. Every actionable task in the plan becomes a Plane work item.
- **Bugs**: discovered errors, failing tests, reproduced defects. Each gets an issue immediately.
- **Explicit requests**: "file this", "track it", "log an issue", "open a ticket".

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

## Bugs → issues

1. Resolve the project. File the issue immediately — no bulk confirmation needed
   for a single bug.
2. `workitem` `create` with:
   - title: short symptom, not the diagnosis ("500 on POST /login", not "broken");
   - description_html: repro steps, expected vs actual, error output, affected
     code path (file:line), environment notes;
   - label `bug` — check with `label` `list` first; create it (`label` `create`,
     any hex color, red suggested) only if missing;
   - priority: set from severity when evident, otherwise leave default and say so.
3. When the bug is fixed: `workitem` `update` the state to Done and add a
   closing `workitem_comment` with the fix summary and commit reference if known.

## Status hygiene

- Completed work → update the work item's state in the same turn, not "later".
- Never leave an item "In Progress" when its work is finished.
- When resuming tracked work, read the item's current state and comments first.

## Guardrails

- `project_id` always comes from the resolution flow — never invented.
- No mass-creation outside the confirmed plan-conversion flow.
- Creating a Plane project, label, or state counts as a write: confirm first.
- Prefer one informative comment over rewriting descriptions wholesale on update.