# opencode machine defaults (Arch/Omarchy)
#
# The shared server URL used for the ntfy notification click-through. This is
# only a default: an OPENCODE_NTFY_URL in shell/shared/opencode.env wins, since
# shell/shared/opencode.sh sources that file first.
export OPENCODE_NTFY_URL="${OPENCODE_NTFY_URL:-$(_opencode_tailnet_url)}"

# The curl installer writes ~/.opencode/bin/opencode; the AUR package installs
# to /usr/bin. Prepend the curl-installer path so both install methods resolve,
# and so an older mise-managed v1 shim stays out of the way.
case ":$PATH:" in
  *":$HOME/.opencode/bin:"*) ;;
  *) export PATH="$HOME/.opencode/bin:$PATH" ;;
esac
