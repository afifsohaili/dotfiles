# opencode machine overrides (Arch/Omarchy)
export OPENCODE_CONFIG="$HOME/Projects/dotfiles/.config/opencode/opencode.linux.json"

# Per-machine opencode env (ntfy topic/url, etc). Gitignored. The systemd
# opencode-server.service reads the same file via EnvironmentFile=.
OPENCODE_ENV_FILE="$HOME/Projects/dotfiles/shell/shared/opencode.env"
if [[ -f "$OPENCODE_ENV_FILE" ]]; then
  set -a
  source "$OPENCODE_ENV_FILE"
  set +a
fi
