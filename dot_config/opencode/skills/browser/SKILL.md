---
name: browser
description: Drive a Chromium browser for web navigation, website debugging, and screenshots. Use when the user asks to open a website, browse, navigate, take a screenshot, check console errors, inspect network requests, debug a web page, fill forms, or test a UI in a real browser.
---

# Browser (Playwright MCP)

Drive a real Chromium browser through the `browser` MCP server. Tools are prefixed `browser_`.

## Core workflow

1. **Navigate**: `browser_navigate` with a URL.
2. **Snapshot**: `browser_snapshot` returns an accessibility tree with element refs like `e12`. This is the source of truth for interacting.
3. **Act**: click, type, hover, drag, select, fill_form — reference elements by their snapshot ref (`target: "e12"`), never by guessing.
4. **Re-snapshot** after actions that change the page.

Never try to interact based on a screenshot. Screenshots are for visual output only; snapshots are for interaction.

## Debugging websites

- **Console**: `browser_console_messages` (pass `level: "error"` or `"all": true` for full session history).
- **Network**: `browser_network_requests` lists requests; `browser_network_request` with the printed index returns headers/body. Use `filter` with a regex (e.g. `/api/.*user`) and `static: false` (default) to skip images/fonts.
- **JS evaluation**: `browser_evaluate` with `() => { ... }` for DOM queries, computed styles, or state inspection.
- **Wait**: `browser_wait_for` with `text`, `textGone`, or `time` instead of polling snapshots.
- **Tabs**: `browser_tabs` to list/open/close/switch.

## Screenshots

`browser_take_screenshot` options:
- default: current viewport
- `fullPage: true`: entire scrollable page
- `target: "e12"`: single element
- `type`: png/jpeg/webp; `filename`: relative name goes to the server output dir

## Profiles

Profiles persist per project automatically: each workspace gets its own profile under `~/.cache/ms-playwright/mcp-chromium-<workspace-hash>`. Logins and cookies are kept per project and survive sessions. Do not pass `--isolated`; that would disable per-project profiles.

## Modes

Two MCP servers are preconfigured; exactly one should be enabled at a time (a persistent profile locks to one browser instance):

- `browser` — headed, window visible on desktop (default)
- `browser-headless` — no window

Switch by flipping `"enabled"` in `~/.config/opencode/opencode.json` under `mcp`, then restart opencode.

## Caveats

- Only one browser entry enabled at a time; two instances of the same workspace profile conflict.
- `browser_run_code_unsafe` executes arbitrary code in the server process (RCE-equivalent) — use only on explicit user request.
- Capabilities enabled: `pdf, vision, devtools` (PDF export, coordinate clicks for canvas/custom widgets, performance tooling).