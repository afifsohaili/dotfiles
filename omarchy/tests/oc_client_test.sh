#!/bin/bash

# Unit tests for `oc` on Linux/Omarchy.
#
# Covers: the client uses discovery (no --server, no serve), an explicit
# directory wins, no argument inside a project targets that project, no
# argument from $HOME falls back to ~/Projects, and the systemd unit is
# started only when it is enabled.

set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

SCRIPT="$HERE/../bin/oc"

if [[ ! -x $SCRIPT ]]; then
  fail "oc is not executable at $SCRIPT"
fi

tmp="$(make_fixture_dir)"
fakehome="$tmp/home"
fakebin="$tmp/bin"
proj="$tmp/proj"
mkdir -p "$fakehome/.opencode/bin" "$fakehome/Projects" "$fakebin" "$proj"
fakehome_real="$(cd "$fakehome" && pwd -P)"

cat >"$fakehome/.opencode/bin/opencode" <<'SH'
#!/bin/bash
: >"${FAKE_OPENCODE_LOG:?}"
for arg in "$@"; do
  printf '%s\n' "$arg" >>"$FAKE_OPENCODE_LOG"
done
printf '%s\n' "${OC_TEST_MARKER:-}" >"${FAKE_OPENCODE_ENV_LOG:?}"
exit 0
SH
chmod +x "$fakehome/.opencode/bin/opencode"

cat >"$fakebin/systemctl" <<'SH'
#!/bin/bash
log="${FAKE_SYSTEMCTL_LOG:?}"
if [[ ${1:-} == --user ]]; then shift; fi
case "${1:-}" in
  is-enabled) exit "${FAKE_SYSTEMCTL_ENABLED:-1}" ;;
  start|restart|enable)
    printf '%s\n' "$*" >>"$log"
    exit 0
    ;;
  *) exit 0 ;;
esac
SH
chmod +x "$fakebin/systemctl"

printf 'OC_TEST_MARKER=loaded\n' >"$tmp/test.env"
args_log="$tmp/opencode.args"
env_log="$tmp/opencode.env"
systemctl_log="$tmp/systemctl.log"
out="$tmp/out"
err="$tmp/err"

run_oc() {
  local cwd="$1"
  shift
  : >"$args_log"
  : >"$systemctl_log"
  (
    cd "$cwd" || exit 99
    HOME="$fakehome_real" \
      PATH="$fakebin:$PATH" \
      OPENCODE_ENV_FILE="$tmp/test.env" \
      FAKE_OPENCODE_LOG="$args_log" \
      FAKE_OPENCODE_ENV_LOG="$env_log" \
      FAKE_SYSTEMCTL_LOG="$systemctl_log" \
      FAKE_SYSTEMCTL_ENABLED="${FAKE_SYSTEMCTL_ENABLED:-1}" \
      "$SCRIPT" "$@"
  ) >"$out" 2>"$err"
  status=$?
  args="$(cat "$args_log")"
  systemctl_calls="$(cat "$systemctl_log")"
}

# --- 1. explicit directory, discovery only ------------------------------
FAKE_SYSTEMCTL_ENABLED=1 run_oc "$tmp" "$proj"
assert_status 0 "$status" "explicit directory exits 0"
assert_eq "$proj" "$(printf '%s\n' "$args" | tail -1)" "explicit directory is the last argument"
assert_contains "$args" "--continue" "client passes --continue"
assert_not_contains "$args" "--server" "client does not pass --server"
assert_not_contains "$args" "serve" "client never starts serve itself"
assert_not_contains "$systemctl_calls" "start opencode-server.service" "disabled unit is not started"
assert_eq "loaded" "$(cat "$env_log")" "env file is sourced for non-login launches"

# --- 2. enabled unit is started before the client ------------------------
FAKE_SYSTEMCTL_ENABLED=0 run_oc "$tmp" "$proj"
assert_contains "$systemctl_calls" "start opencode-server.service" "enabled unit is started"

# --- 3. no argument inside a project targets that project ---------------
proj_real="$(cd "$proj" && pwd -P)"
run_oc "$proj_real"
assert_status 0 "$status" "no argument in a project exits 0"
assert_eq "$proj_real" "$(printf '%s\n' "$args" | tail -1)" "current directory is targeted"

# --- 4. no argument from \$HOME falls back to ~/Projects -----------------
home_real="$(cd "$fakehome" && pwd -P)"
run_oc "$home_real"
assert_status 0 "$status" "no argument from HOME exits 0"
assert_eq "$fakehome_real/Projects" "$(printf '%s\n' "$args" | tail -1)" "HOME falls back to ~/Projects"
