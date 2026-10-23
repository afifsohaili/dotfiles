# Shared opencode env: ntfy settings and the tailnet URL helper.
# The 15001 server is the managed background service; its port, hostname, and
# password live in ~/.config/opencode/service.json, provisioned by install.sh.
# Nothing here needs to generate or export a server password.
#
# Sourced before shell/{mac,linux}/opencode.sh, so a value here wins over the
# per-machine OPENCODE_NTFY_URL default.
OPENCODE_ENV_FILE="${OPENCODE_ENV_FILE:-$HOME/Projects/dotfiles/shell/shared/opencode.env}"
if [[ -f "$OPENCODE_ENV_FILE" ]]; then
  set -a
  source "$OPENCODE_ENV_FILE"
  set +a
fi

# Default URL for the shared server over the tailnet. Derived at runtime so no
# MagicDNS hostname is committed to the public repo. Falls back to loopback.
_opencode_tailnet_url() {
  local dns=""
  if command -v tailscale >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    dns="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null)"
    dns="${dns%.}"
  fi
  if [[ -n "$dns" ]]; then printf 'http://%s:15001' "$dns"; else printf 'http://127.0.0.1:15001'; fi
}
