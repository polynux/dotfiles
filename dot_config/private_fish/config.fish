if status is-interactive
    # Commands to run in interactive sessions can go here
    # eval (zellij setup --generate-auto-start fish | string collect)

    # source ~/.config/fish/async.fish

    fish_add_path "$HOME/.local/share/pnpm"
    fish_add_path "$HOME/.local/bin"
    fish_add_path $HOME/.cargo/bin
    fish_add_path $HOME/.config/emacs/bin
    fish_add_path "$HOME/.local/share/bob/nvim-bin"
    fish_add_path "$HOME/.go/bin"

    set -gx EDITOR nvim

    bind \cH backward-kill-word
    bind [3\;5~ kill-word

    bind \cn nvims

    source ~/.config/fish/alias.fish

    # check if SSH_AUTH_SOCK is set
    if test -z "$SSH_AUTH_SOCK"
        for var in SSH_AUTH_SOCK ;
            tmux setenv -g $var (tmux showenv -g $var)
        end
    end

    function fish_prompt -d "Write out the prompt"
        # This shows up as USER@HOST /home/user/ >, with the directory colored
        # $USER and $hostname are set by fish, so you can just use them
        # instead of using `whoami` and `hostname`
        printf '%s@%s %s%s%s > ' $USER $hostname \
            (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
    end

    function fish_greeting
    end

    function fish_title
        set -q argv[1]; or set argv fish
        # Looks like ~/d/fish: git log
        # or /e/apt: fish
        echo (fish_prompt_pwd_dir_length=1 prompt_pwd): $argv;
    end

    function starship_transient_prompt_func
      starship module character
      starship module time
    end
    function starship_transient_rprompt_func
      starship module time
    end
    # starship init fish | source
    # enable_transience
    oh-my-posh init fish --config ~/.config/omp/config.omp.toml | source
    zoxide init fish | source

    source "$HOME/.asdf/asdf.fish"
    # set -gx DISPLAY (cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0 #GWSL
    # set -gx PULSE_SERVER tcp:(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}') #GWSL

    # pnpm
    set -gx PNPM_HOME "/home/polynux/.local/share/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
      set -gx PATH "$PNPM_HOME" $PATH
    end
    # pnpm end

    set -gx GOPATH "$HOME/.go"
end
