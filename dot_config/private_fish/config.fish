if status is-interactive
    # Commands to run in interactive sessions can go here
    # eval (zellij setup --generate-auto-start fish | string collect)
end

source ~/.config/fish/async.fish

set PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"
fish_add_path "$HOME/.local/bin"
fish_add_path $HOME/.cargo/bin

set -gx EDITOR nvim

bind \cH backward-kill-word
bind [3\;5~ kill-word

source ~/.config/fish/alias.fish

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

starship init fish | source

source "$HOME/.asdf/asdf.fish"
