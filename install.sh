cp -f vimrc ~/.SpaceVim/
cp -f init.toml ~/.SpaceVim.d/
cp -f zshrc ~/.zshrc

# zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
