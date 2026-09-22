# Fallback secret export from ~/.secrets files.
# Only fills gaps: when Bitwarden (bitwarden.fish) did not provide the var,
# e.g. vault locked, item missing, or non-interactive sessions.
# Format: $KEY_FILE -> set -gx KEY (cat $KEY_FILE); files must be mode 600.

if not set -q PLANE_API_KEY; and test -f "$HOME/.secrets/plane-api-key"
    set -gx PLANE_API_KEY (cat "$HOME/.secrets/plane-api-key")
end
