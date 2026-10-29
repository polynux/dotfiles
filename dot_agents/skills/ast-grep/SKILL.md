---
name: ast-grep
description: Structural code search and rewrite with ast-grep. Use when searching code for calls, definitions, or usages, or when refactoring or renaming across files, instead of grep, rg, or sed.
---

# ast-grep

Match code by syntax tree, not text: whitespace, formatting, and comments stop mattering, and strings or comments that merely contain the name don't match. Reach for `rg` only for plain text (log messages, config keys, prose).

## Search

```bash
ast-grep -p 'console.log($$$ARGS)' -l ts src/
ast-grep -p '$OBJ.fetch($URL)' -l py --json=stream . | jq -r '"\(.file):\(.range.start.line+1) \(.metaVariables.single.URL.text)"'
```

- `$X` matches one node, `$$$X` matches zero or more (arguments, statements), and `$_` matches any node without capturing it. Reusing a name (`$A == $A`) requires the same code in both places.
- A pattern must be valid code and matches a **whole node**: `env::var($K)` does not match `std::env::var(...)`. Zero matches → try the other form, or check how the pattern parsed with `--debug-query=ast`.
- In `--json` output, lines are 0-based: add 1.
- `ast-grep outline <file|dir>` gives a cheap map of symbols with line numbers before you read a whole file.

## Rewrite

```bash
ast-grep -p 'console.log($$$A)' -r 'logger.info($$$A)' -l ts src/      # preview diff
ast-grep -p 'console.log($$$A)' -r 'logger.info($$$A)' -l ts -U src/   # apply
```

Preview first, then apply with `-U`. Captured metavariables are substituted into the `-r` template.

## Rules: when one pattern isn't enough

For context ("inside X", "contains Y", "but not Z"), write an inline YAML rule. Single-quote it so the shell leaves `$` alone:

```bash
ast-grep scan --inline-rules 'id: await-no-try
language: ts
rule:
  kind: function_declaration
  has: {pattern: await $E, stopBy: end}
  not: {has: {kind: try_statement, stopBy: end}}' src/
```

- Atomic: `pattern`, `kind` (a node type), `regex` (matches the node's text).
- Relational: `inside`, `has`, `follows`, `precedes`. **Always add `stopBy: end`**: the default only checks direct neighbours, so the rule silently misses deeper matches.
- Composite: `all`, `any`, `not`. Keys in one rule object are ANDed together.
- Filter a capture: add `constraints: {E: {regex: '^fetch'}}` at the top level, next to `rule:`.
- To find `kind` names, dump the tree: `ast-grep -p '<sample code>' -l ts --debug-query=ast`.
- Add `fix: '<template>'` next to `rule:` and pass `-U` to rewrite.
