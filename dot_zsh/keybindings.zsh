typeset -A key
    key=(
        BackSpace  "${terminfo[kbs]}"
        Home       "${terminfo[khome]}"
        End        "${terminfo[kend]}"
        Insert     "${terminfo[kich1]}"
        Delete     "${terminfo[kdch1]}"
        Up         "${terminfo[kcuu1]}"
        Down       "${terminfo[kcud1]}"
        Left       "${terminfo[kcub1]}"
        Right      "${terminfo[kcuf1]}"
        PageUp     "${terminfo[kpp]}"
        PageDown   "${terminfo[knp]}"
    )

bindkey "^A" beginning-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3;5~" kill-word
bindkey "^[[3~" delete-char 
bindkey "^H" backward-kill-word
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-search

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

autoload -U select-word-style
select-word-style bash
