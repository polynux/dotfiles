#!/bin/bash

if [ ! -d ~/.local/bin ]; then
    mkdir -p ~/.local/bin
fi

if ! command -v oh-my-posh &> /dev/null
then
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
fi
