# macOS only. On Linux/Omarchy, `oc` is the script at omarchy/bin/oc (symlinked
# to ~/.local/bin/oc), which uses the systemd opencode-server service. Defining
# this function there would shadow the script and start a second server on
# 15001; it also checks readiness with lsof, which Omarchy does not ship.
if [[ "$(uname -s)" == "Darwin" ]]; then
  function oc() {
    reload
    if [ "$1" = "--restart" ]; then
      pkill opencode
      shift
      local i=0
      while lsof -i:15001 >/dev/null 2>&1 && [ $i -lt 20 ]; do
        sleep 0.5
        i=$((i + 1))
      done
    fi
    if ! lsof -i:15001 >/dev/null 2>&1; then
      opencode serve --port 15001 --hostname 0.0.0.0 &
      local i=0
      while ! lsof -i:15001 >/dev/null 2>&1 && [ $i -lt 30 ]; do
        sleep 0.5
        i=$((i + 1))
      done
    fi
    opencode attach http://0.0.0.0:15001 --dir `pwd` $1
  }
fi
