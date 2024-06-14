if [[ -s "/usr/bin/lsd" ]]; then
    alias ls="lsd"
fi
alias la="ls -a"
alias l="ls -la"
alias ll="ls -l"
alias vim="nvim"
alias svim="/usr/bin/vim"
alias lazy="NVIM_APPNAME=lazyvim nvim"
alias nvchad="NVIM_APPNAME=nvchad nvim"
alias kick="NVIM_APPNAME=kickvim nvim"
alias rsc="ssh -At guillaume.dorce@rsc.bm-services.com 'cd /volumes/databases/; bash -li'"
alias arn="ssh -At guillaume.dorce@arena.bms.lan bash"
alias sky="ssh -At guillaume.dorce@sas.sky.lan bash"
alias ta="tmux a"
alias tm="tmux"
alias gw="gulp watch"
alias colors="$HOME/.config/scripts/colors.sh"

alias ga="git add"
alias gaa="git add --all"
alias gst="git status"
alias gpr="git pull --rebase"
alias lg="lazygit"

alias awtest="Xephyr :5 -screen 1600x900 & sleep 1 ; DISPLAY=:5 awesome"

alias bat="batcat"

alias cm="chezmoi"
alias cmcd="cd $(chezmoi source-path)"
alias cme="cm edit"
alias cma="cm apply -v"
alias cmd="cm diff"
alias cmu="cm update"

alias c="code"
alias cl="clear"
