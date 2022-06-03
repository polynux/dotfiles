ln -s "$PWD/zsh/zshrc" "$HOME/.zshrc"
ln -s "$PWD/zsh/zshenv" "$HOME/.zshenv"
ln -s "$PWD/zsh/zprofile" "$HOME/.zprofile"
ln -s "$PWD/.p10k.zsh" "$HOME/.p10k.zsh"
ln -s "$PWD/nvim" "$HOME/.config/nvim"

ln -s "$PWD/.tmux.conf" "$HOME/.tmux.conf"

cp -av "$PWD/.config/scripts/" "$HOME/.config/"
