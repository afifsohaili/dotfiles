# opencode machine defaults (macOS)
#
# The shared server URL used for the ntfy notification click-through. This is
# only a default: an OPENCODE_NTFY_URL in shell/shared/opencode.env wins, since
# shell/shared/opencode.sh sources that file first.
export OPENCODE_NTFY_URL="${OPENCODE_NTFY_URL:-http://afifs-macbook-pro.taila5c1b8.ts.net:15001}"
