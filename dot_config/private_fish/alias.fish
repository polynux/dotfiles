if type -q lsd
    alias ls="lsd"
end
abbr -a la ls -a
# alias l="ls -la"
abbr -a l ls -la
alias ll="ls -l"
alias vim="nvim"
alias svim="/usr/bin/vim"
alias lazy="env NVIM_APPNAME=lazyvim nvim"
alias nvchad="env NVIM_APPNAME=nvchad nvim"
alias kick="env NVIM_APPNAME=kickvim nvim"

alias rsc="ssh -t guillaume.dorce@rsc.bm-services.com 'cd /volumes/databases/; bash -li'"
abbr -a arn ssh -t guillaume.dorce@arena.bms.lan bash
alias sky="ssh -t guillaume.dorce@sas.sky.lan bash"
alias skyh="ssh -t -p 302 guillaume.dorce@hst.bm-services.com 'cd /volumes/hosting-logs ; /bin/bash --login'"
alias gw="gulp watch"
alias colors="$HOME/.config/scripts/colors.sh"

alias ga="git add"
abbr -a gd git diff
alias gaa="git add --all"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gcam="git commit --amend -m"
alias gp="git push"
alias gst="git status"
alias gpr="git pull --rebase"
alias lg="lazygit"
abbr -a gui gitui

alias awtest="Xephyr :5 -screen 1600x900 & sleep 1 ; DISPLAY=:5 awesome"

if type -q batcat
    alias bat="batcat"
end

alias cm="chezmoi"
alias cmcd="cd (chezmoi source-path)"
alias cme="cm edit"
alias cma="cm apply -v"
alias cmd="cm diff"
alias cmu="cm update"

abbr c code
abbr cl clear

# multiplexer
alias ta="tmux a"
alias tm="tmux"
