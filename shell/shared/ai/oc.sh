# macOS only. On Linux/Omarchy, `oc` is the script at omarchy/bin/oc (symlinked
# to ~/.local/bin/oc), which starts the systemd unit. Defining this function
# there would shadow the script.
#
# V2: port 15001 is owned by the managed background service
# (`opencode serve --service`). Its port, hostname, and password live in
# ~/.config/opencode/service.json, provisioned by install.sh. The client takes
# the directory as a positional argument and discovers that service, so there
# is no `--server` and no explicit serve here. A first argument that is not a
# flag is passed through as `--session <id>`.
if [[ "$(uname -s)" == "Darwin" ]]; then
  function oc() {
    reload
    local -a session_arg=()
    if [ "$1" = "--restart" ]; then
      opencode service restart
      shift
    fi
    if [ -n "${1:-}" ]; then
      session_arg=(--session "$1")
      shift
    else
      session_arg=(--continue)
    fi
    opencode "${session_arg[@]}" "$(pwd)"
  }
fi
