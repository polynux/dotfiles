curl -sLf https://spacevim.org/install.sh | bash
cp -f vimrc ~/.SpaceVim/
cp -f init.toml ~/.SpaceVim.d/

# oh-my-zsh install
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

cp -f zshrc ~/.zshrc

# zsh plugins
export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
