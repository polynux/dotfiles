#!/bin/bash

if [ ! -d ~/.local/bin ]; then
    mkdir -p ~/.local/bin
fi

if ! command -v oh-my-posh &> /dev/null
then
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
fi

# Variety fork (polynux/variety feat/reddit-rss-fallback): userspace venv, no sudo.
# Provides ~/.local/bin/variety with Reddit RSS fallback + cookie/token auth.
if [ ! -x "$HOME/.local/bin/variety" ] || ! "$HOME/.local/bin/variety" --version &>/dev/null; then
    NEED_VARIETY_INSTALL=1
else
    # reinstall if fork checkout is newer than venv marker
    NEED_VARIETY_INSTALL=0
fi
if [ "${NEED_VARIETY_INSTALL:-0}" = "1" ] || [ ! -d "$HOME/.local/share/variety-fork-venv" ]; then
    if [ ! -d "$HOME/dev/variety" ]; then
        if command -v gh &>/dev/null; then
            gh repo clone polynux/variety "$HOME/dev/variety" -- --branch feat/reddit-rss-fallback 2>/dev/null || git clone --branch feat/reddit-rss-fallback https://github.com/polynux/variety.git "$HOME/dev/variety"
        else
            git clone --branch feat/reddit-rss-fallback https://github.com/polynux/variety.git "$HOME/dev/variety"
        fi
    fi
    uv venv --system-site-packages --python 3.14 "$HOME/.local/share/variety-fork-venv"
    uv pip install --python "$HOME/.local/share/variety-fork-venv/bin/python" -e "$HOME/dev/variety"
    echo "/home/polynux/dev/variety" > "$HOME/.local/share/variety-fork-venv/lib/python3.14/site-packages/zz-fork-first.pth"
    # wrapper (single entry, PYTHONPATH forces fork shadowing over /usr/lib system variety)
    printf '%s\n' '#!/bin/sh' '# Userspace Variety fork (chezmoi managed)' 'export PYTHONPATH="/home/polynux/dev/variety:${PYTHONPATH:-}"' 'exec "$HOME/.local/share/variety-fork-venv/bin/variety" "$@"' > "$HOME/.local/bin/variety"
    chmod +x "$HOME/.local/bin/variety"
fi
