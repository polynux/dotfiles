---
description: Map this project to a Plane project by adding/updating "Plane project: <name>" in AGENTS.md.
agent: build
---

Set the Plane project mapping for the current project root.

Input: $ARGUMENTS — the Plane project name (or identifier). If empty, this is a
query/setup task instead of a write task.

Steps:

1. **Determine the target project:**
   - If $ARGUMENTS is non-empty, use it as the project name/identifier.
   - If empty, check whether AGENTS.md already has a `Plane project:` line and
     report it; otherwise, if the plane MCP tools are available, run
     `project` `list` and show the projects so the user can pick one. If the
     tools are unavailable, explain that plane is disabled (enable with
     `"mcp": { "plane": { "enabled": true } }` in the project's opencode.json)
     and stop without writing anything.

2. **Validate (only when plane tools are available):** resolve the given name
   against `project` `list` (case-insensitive). If there is no match or the
   match is ambiguous, report the candidates and stop — do not write a guess.

3. **Write the mapping in AGENTS.md at the project root:**
   - Create AGENTS.md if it does not exist.
   - If a `Plane project: <something>` line already exists, replace its value.
   - Otherwise append this section (before any trailing content, at the end of
     the file; create a `## Plane` heading only if the file has no suitable
     existing section to extend):

     ```
     ## Plane

     Plane project: <resolved project name>
     ```

   - Never touch anything else in AGENTS.md. Idempotent edits only.

4. **Report:** state exactly what was written (file path, final line) and remind
   that the `plane-issues` skill reads this line for issue tracking.

Never invent a project name. If validation fails, leave AGENTS.md untouched.