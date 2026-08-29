---
name: chezmoi
description: Use when editing any dotfile or config file under $HOME (e.g. ~/.config, ~/.zshrc, ~/.gitconfig), when the user mentions chezmoi, dotfiles, or asks to track/save/commit/persist config changes. Ensures edits go through the chezmoi source dir and get committed.
---

# Chezmoi dotfile workflow

The user manages their dotfiles with chezmoi. Never edit a home config file
without accounting for chezmoi: live files are generated from the source
directory, so an edit to the live file alone is lost on the next
`chezmoi apply`.

- Live target files: under `$HOME` (e.g. `$HOME/.config/…`)
- Source of truth: `$(chezmoi source-path)` (a git repo; normally `~/.local/share/chezmoi`)

## Before editing

Check whether the file is already managed:

```sh
chezmoi managed --path <file> >/dev/null && echo managed
```

- If managed: edit via the source (`chezmoi edit <file>`) or edit live, then re-add. Be aware the source file may be a template (`<file>.tmpl`) and renamed paths live at `encrypted_…` / `dot_…` under the source dir — use `chezmoi source-path <file>` to find the exact source file.
- If not managed: confirm with the user, then `chezmoi add <file>` first.
- Files may contain templates (`{{ … }}`) or secrets — never commit decrypted secret contents, and do not cat files that look like credentials.

## After editing (do this every time)

1. Show the user what will change:

   ```sh
   chezmoi diff
   ```

2. Record the change into the source directory:

   ```sh
   chezmoi add <file>
   ```

3. Commit in the source dir:

   ```sh
   git -C "$(chezmoi source-path)" add -A
   git -C "$(chezmoi source-path)" commit -m "<short description>"
   ```

   Use `git -C` instead of `cd`. If there is nothing staged, skip silently.

4. Only on explicit request (this overwrites live files):

   ```sh
   chezmoi apply
   ```

## Rules

- A session that edited a home config file is NOT done until the change is committed in the chezmoi source repo.
- Do not run `chezmoi apply` or `chezmoi init` unless asked.
- On a fresh machine the user restores config with `chezmoi init <repo> && chezmoi apply` — mention this only when creating brand-new tracked files.