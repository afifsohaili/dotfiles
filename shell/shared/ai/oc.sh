# macOS only. On Linux/Omarchy, `oc` is the script at omarchy/bin/oc (symlinked
# to ~/.local/bin/oc), which uses the systemd opencode-server service. Defining
# this function there would shadow the script and start a second server on
# 15001; it also checks readiness with lsof, which Omarchy does not ship.
#
# V2 note: `opencode attach` is gone. The client takes the directory as a
# positional argument and connects with `--server`. The server password comes
# from shell/shared/opencode.sh and must match on both sides. A first argument
# that is not a flag is passed through as `--session <id>`.
if [[ "$(uname -s)" == "Darwin" ]]; then
  function oc() {
    reload
    local -a session_arg=()
    if [ "$1" = "--restart" ]; then
      pkill opencode
      shift
      local i=0
      while lsof -i:15001 >/dev/null 2>&1 && [ $i -lt 20 ]; do
        sleep 0.5
        i=$((i + 1))
      done
    fi
    if [ -n "${1:-}" ]; then
      session_arg=(--session "$1")
      shift
    else
      session_arg=(--continue)
    fi
    if ! lsof -i:15001 >/dev/null 2>&1; then
      # Loopback only; expose to the tailnet with `tailscale serve`.
      opencode serve --port 15001 --hostname 127.0.0.1 &
      local i=0
      while ! lsof -i:15001 >/dev/null 2>&1 && [ $i -lt 30 ]; do
        sleep 0.5
        i=$((i + 1))
      done
    fi
    opencode --server http://127.0.0.1:15001 "${session_arg[@]}" "$(pwd)"
  }
fi
