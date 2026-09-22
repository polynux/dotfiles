# bitwarden.fish — on-demand Bitwarden secret loading for fish
#
# NOTHING runs at shell startup: no unlock prompt, no env vars exported.
# When you need the keys (e.g. before launching an agent), run:
#
#   bitwarden          — load keys into THIS shell (unlocks once per boot if needed)
#   bitwarden export   — refresh keys: sync the vault + re-export (no unlock prompt)
#   bitwarden -f       — force re-unlock (new session even if one exists)
#   bitwarden lock     — wipe the stored session and unset all exported vars
#   bw-status          — show session/key state
#
# The BW_SESSION key lives in a tmpfs keyring under $XDG_RUNTIME_DIR →
# memory only, lost at reboot, so the master password is asked once per boot.
# Keys are exported into the current shell only; child processes (e.g.
# freebuff and its MCP servers) inherit them. Other shells stay clean.
#
# Declaring secrets (one line per env var, e.g. in config.fish or conf.d):
#   set -g BW_EXPORTS PLANE_API_KEY GITHUB_TOKEN MY_NEW_KEY
# Vault item name is derived from the var name: PLANE_API_KEY → "plane-api-key".
# Override an item name with: set -g BW_ITEM_MY_NEW_KEY "custom item name"
# If the vault has no item, the file ~/.secrets/<item-name> is used as a
# fallback (mode 600, single line with the raw value).

# ---------------------------------------------------------------- config ----
set -g BW_KEYRING_DIR "$XDG_RUNTIME_DIR/bitwarden"
set -g BW_KEYRING_SESSION "$BW_KEYRING_DIR/session"
set -g BW_KEYRING_MODE 600
set -q BW_EXPORTS; or set -g BW_EXPORTS PLANE_API_KEY

# ---------------------------------------------------------------- helpers ---
function __bw_valid_session --description "Test whether the current BW_SESSION env var is usable"
    set -q BW_SESSION; or return 1
    bw unlock --check >/dev/null 2>&1
end

function __bw_item_name --description "Vault item name for an env var (BW_ITEM_<VAR> override, else derived)"
    set -l var $argv[1]
    set -l override_var "BW_ITEM_$var"
    if set -q $override_var
        echo $$override_var
    else
        string lower (string replace -ra '_' '-' -- $var)
    end
end

function __bw_fetch --description "Fetch one item (password field, falling back to notes); echo value or fail"
    set -l item $argv[1]
    set -l val (bw get password "$item" 2>/dev/null)
    if test $status -ne 0; or test -z "$val"
        set val (bw get notes "$item" 2>/dev/null | string collect | string trim)
    end
    test -n "$val"; and echo "$val"
end

function __bw_export_all --description "Export every declared secret (vault first, ~/.secrets file fallback)"
    set -l failures 0
    for var in $BW_EXPORTS
        set -l item (__bw_item_name "$var")
        set -l val (__bw_fetch "$item")
        if test $status -eq 0
            set -gx $var "$val"
            echo "  ✓ $var ← vault:'$item'"
        else if test -f "$HOME/.secrets/$item"
            set -gx $var (cat "$HOME/.secrets/$item")
            echo "  ✓ $var ← file:~/.secrets/$item"
        else
            echo "  ✗ $var: no vault item '$item' and no ~/.secrets/$item" >&2
            set failures (math $failures + 1)
        end
    end
    return $failures
end

function __bw_sync --description "Sync the vault; warn but never block on error"
    if not bw sync >/dev/null 2>&1
        echo "bw: sync failed (continuing with the local vault copy)" >&2
        return 1
    end
    return 0
end

# ---------------------------------------------------------------- command ---
function bitwarden --description "Load Bitwarden secrets into the current shell (on demand)"
    set -l force 0
    set -l mode
    for a in $argv
        switch "$a"
            case lock
                set mode lock
            case export
                set mode export
            case -f --force
                set force 1
            case '*'
                echo "bitwarden: unknown argument '$a' (use: export, lock, -f)" >&2
                return 2
        end
    end

    if test "$mode" = lock
        rm -f "$BW_KEYRING_SESSION"
        set -e BW_SESSION
        for var in $BW_EXPORTS
            set -e $var
        end
        echo "Bitwarden session locked (deleted from keyring)."
        return 0
    end

    # Fast path: a session already exists (env or tmpfs keyring), no prompt.
    if test $force -eq 0
        if not __bw_valid_session; and test -f "$BW_KEYRING_SESSION"
            set -gx BW_SESSION (cat "$BW_KEYRING_SESSION")
        end
        if __bw_valid_session
            # Sync only on the explicit 'export' trigger, to keep 'load' fast.
            if test "$mode" = export
                __bw_sync
            end
            __bw_export_all
            return $status
        end
        if test "$mode" = export
            echo "bw: no valid session — run 'bitwarden' to unlock first." >&2
            return 1
        end
    end

    # Slow path: interactive unlock, with an explicit prompt so it's obvious
    # that the shell is waiting for input.
    echo "🔑 To load your secrets, the Bitwarden vault must be unlocked."
    echo "   (Once per boot — the session is kept in memory only, lost at reboot.)"
    read -l -s -P "   Master password (input hidden): " pw
    if test $status -ne 0; or test -z "$pw"
        echo "Bitwarden unlock cancelled." >&2
        return 1
    end

    mkdir -p "$BW_KEYRING_DIR"
    chmod 700 "$BW_KEYRING_DIR"
    set -gx BW_PASSWORD "$pw"
    set -l tmp "$BW_KEYRING_SESSION.tmp.$fish_pid"
    if not bw unlock --passwordenv BW_PASSWORD --raw >"$tmp" 2>/dev/null
        set -e BW_PASSWORD
        rm -f "$tmp"
        echo "Bitwarden unlock failed: wrong password?" >&2
        return 1
    end
    set -e BW_PASSWORD
    if not test -s "$tmp"
        rm -f "$tmp"
        echo "Bitwarden unlock produced no session key." >&2
        return 1
    end

    mv "$tmp" "$BW_KEYRING_SESSION"
    chmod $BW_KEYRING_MODE "$BW_KEYRING_SESSION"
    set -gx BW_SESSION (cat "$BW_KEYRING_SESSION")

    echo "   Syncing vault…"
    __bw_sync
    __bw_export_all
    and echo "Secrets loaded into this shell (session kept for this boot)."
end

# ---------------------------------------------------------------- status ----
function bw-status --description "Show Bitwarden session state"
    if __bw_valid_session
        echo "BW_SESSION: valid (from environment)"
    else if test -f "$BW_KEYRING_SESSION"
        echo "BW_SESSION: stored (tmpfs) — run 'bitwarden' to load keys in this shell"
    else
        echo "BW_SESSION: none — run 'bitwarden' to unlock and load keys"
    end
    for var in $BW_EXPORTS
        if set -q $var
            echo "$var: set"
        else
            echo "$var: not set"
        end
    end
end
