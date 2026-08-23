# hyprland config

## Chezmoi workflow

The live config at `$HOME/.config/hypr/` is managed by chezmoi from `$HOME/.local/share/chezmoi/`.

```sh
chezmoi add ~/.config/hypr/<file>   # Track a changed file
chezmoi diff                           # Preview changes
chezmoi apply                          # Apply source to target
```

Commit changes in the chezmoi directory:

```sh
git -C $HOME/.local/share/chezmoi add -A
git -C $HOME/.local/share/chezmoi commit -m "description"
```
