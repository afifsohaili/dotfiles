
function oc() {
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
