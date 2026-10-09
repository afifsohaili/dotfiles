# Shared opencode env: the password for the shared server on port 15001.
# The server (systemd on Linux, `oc` on macOS) and every client
# (`oc`, `opencode --server http://127.0.0.1:15001`) must present the same
# OPENCODE_PASSWORD. V2 servers always require one; without a shared value the
# client fails with "Server ... requires a password; set OPENCODE_PASSWORD".
#
# Generated on first use and appended to the gitignored env file so every shell
# and both machines agree. Delete OPENCODE_PASSWORD from the file to rotate.
#
# Sourced before shell/{mac,linux}/opencode.sh, so a value here wins over the
# per-machine OPENCODE_NTFY_URL default.
OPENCODE_ENV_FILE="${OPENCODE_ENV_FILE:-$HOME/Projects/dotfiles/shell/shared/opencode.env}"
if [[ -f "$OPENCODE_ENV_FILE" ]]; then
  set -a
  source "$OPENCODE_ENV_FILE"
  set +a
fi
if [[ -z "${OPENCODE_PASSWORD:-}" ]]; then
  export OPENCODE_PASSWORD="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
  ( umask 077; printf 'OPENCODE_PASSWORD=%s\n' "$OPENCODE_PASSWORD" >> "$OPENCODE_ENV_FILE" )
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
