#!/bin/sh
# Sync ~/.claude/skills symlinks to ~/.agents/skills.
# skill-list hash: e27a2dfeb7094e34d35b7b981f4e398fe3d6f2af34ea98024ae8598efd42cdfa  (update by re-running the audit; change triggers re-run)
set -eu
src="$HOME/.agents/skills"
dst="$HOME/.claude/skills"
[ -d "$src" ] || { echo "no $src, skipping"; exit 0; }
mkdir -p "$dst"
for entry in "$src"/*; do
    name=$(basename "$entry")
    target="$dst/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
        continue
    fi
    ln -s "../../.agents/skills/$name" "$target"
    echo "linked ~/.claude/skills/$name"
done
