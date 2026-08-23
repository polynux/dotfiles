# kickvim

Neovim configuration based on kickstart.nvim, managed via chezmoi.

## Config location

- **Config dir:** `$HOME/.config/kickvim/`
- **Data dir (plugins, lazy.nvim):** `$HOME/.local/share/kickvim/`
- **Chezmoi source:** `$HOME/.local/share/chezmoi/`
- **NVIM_APPNAME:** `kickvim`

## Structure

```
$HOME/.config/kickvim/
├── init.lua                       # Entry point: leader keys, lazy.nvim setup, LSP, blink.cmp, lualine, telescope (buffers/oldfiles/help/diagnostics/LSP pickers)
├── lazy-lock.json                 # Pinned plugin versions
├── lua/
│   ├── kickstart/
│   │   └── plugins/
│   │       └── debug.lua          # DAP config (nvim-dap, nvim-dap-ui, nvim-dap-go)
│   ├── custom/
│   │   └── plugins/               # All custom plugin specs (auto-imported by lazy.nvim)
│   │       ├── ai.lua             # minuet-ai (Ollama Cloud inline completion via blink.cmp)
│   │       ├── opencode.lua       # opencode.nvim (AI chat agent via opencode CLI)
│   │       ├── neorg.lua          # Neorg notes (luarocks treesitter parsers)
│   │       ├── nonels.lua         # none-ls (diagnostics: phpstan, code_actions: gitsigns)
│   │       ├── possessions.lua     # Session management
│   │       ├── fff.lua             # fff.nvim (file/grep/frecency picker, replaces telescope-frecency)
│   │       └── ...                # Other plugins (autopairs, db, indent, leap, etc.)
│   └── minuet-spinner.lua         # Lualine spinner module for minuet request status
└── doc/
```

## Plugin management

Plugins are managed by **lazy.nvim**. Custom plugins live in `lua/custom/plugins/*.lua` and are auto-imported via `{ import = 'custom.plugins' }` in `init.lua`.

- Sync plugins: `:Lazy sync`
- Update plugins: `:Lazy update`
- Lock file: `lazy-lock.json` (committed for reproducibility)

## Chezmoi workflow

The live config at `$HOME/.config/kickvim/` is managed by chezmoi from `$HOME/.local/share/chezmoi/`.

```sh
chezmoi add ~/.config/kickvim/<file>   # Track a changed file
chezmoi diff                           # Preview changes
chezmoi apply                          # Apply source to target
```

Commit changes in the chezmoi directory:

```sh
git -C $HOME/.local/share/chezmoi add -A
git -C $HOME/.local/share/chezmoi commit -m "description"
```

## Verify config

Run neovim headless to check for load errors:

```sh
NVIM_APPNAME=kickvim nvim --headless "+qa" 2>&1
```

If it exits cleanly (no output), the config loads without errors. To check plugin health:

```sh
NVIM_APPNAME=kickvim nvim --headless "+checkhealth" "+qa" 2>&1
```

## AI setup

- **Inline completion:** minuet-ai via Ollama Cloud (`deepseek-v4-flash:0731-cloud`), triggered manually with `<C-space>` in blink.cmp
- **Chat agent:** opencode.nvim using the `opencode` CLI (v1.17+), toggle with `<leader>og`
- Ollama runs locally at `http://localhost:11434` and proxies to cloud models