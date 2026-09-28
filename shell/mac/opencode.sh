# opencode machine overrides (macOS)
export OPENCODE_CONFIG="$HOME/Projects/dotfiles/.config/opencode/opencode.mac.json"

# Per-machine opencode env (ntfy topic/url, etc). Gitignored. Falls back to the
# macOS defaults if the file is absent.
OPENCODE_ENV_FILE="$HOME/Projects/dotfiles/shell/shared/opencode.env"
if [[ -f "$OPENCODE_ENV_FILE" ]]; then
  set -a
  source "$OPENCODE_ENV_FILE"
  set +a
else
  export OPENCODE_NTFY_URL="http://afifs-macbook-pro.taila5c1b8.ts.net:15001"
fi
