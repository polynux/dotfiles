source $HOME/.antidote/antidote.zsh
antidote load

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
autoload -Uz promptinit && promptinit && prompt powerlevel10k

export ZCONFIG="$HOME/dotfiles/zsh"
export FZF_DIR="$ZCONFIG/fzf"
export EDITOR="nvim"
export FZF_DEFAULT_COMMAND='find . \! \( -type d -path ./.git -prune \) \! -type d \! -name '\''*.tags'\'' -printf '\''%P\n'\'

PATH="$HOME/.local/bin:$HOME/.local/share/pnpm:/usr/local/go/bin:$PATH"

source "$HOME/.cargo/env"
source "$FZF_DIR/completion.zsh"
source "$FZF_DIR/key-bindings.zsh"
source "$ZCONFIG/keybindings.zsh"

if [[ -s "/usr/bin/lsd" ]]; then
    alias ls="lsd"
fi
alias la="ls -a"
alias l="ls -la"
alias ll="ls -l"
alias vim="nvim"
alias svim="/usr/bin/vim"
alias rsc="ssh -A guillaume.dorce@rsc.bm-services.com 'cd /volumes/databases/; bash -li'"
alias arn="ssh -A guillaume.dorce@arena.bms.lan"
alias ta="tmux a"
alias npm="pnpm"
alias gw="gulp watch"
alias colors="$HOME/.config/scripts/colors.sh"

alias ga="git add"
alias gaa="git add --all"
alias gst="git status"
alias gpr="git pull --rebase"

if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval `ssh-agent -s`
    ssh-add
	clear
fi

# pnpm
export PNPM_HOME="/home/polynux/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

function mkdir_and_cd() {
    mkdir -p "$1"
    cd $1
}

alias mkc=mkdir_and_cd

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS 
