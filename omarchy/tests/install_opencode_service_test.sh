#!/bin/bash

# Tests for install.sh's managed-service provisioning.
#
# Covers: port and hostname are written when unset, a service running on a port
# other than :15001 triggers daemon-reload plus restart, a service already on
# :15001 does not report drift, and macOS restarts the managed service instead
# of a unit.
#
# Runs install.sh with --dry-run and a fake opencode binary, so nothing on the
# machine is touched.

set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

INSTALL="$HERE/../../install.sh"

if [[ ! -f $INSTALL ]]; then
  fail "install.sh not found at $INSTALL"
fi

tmp="$(make_fixture_dir)"
home="$tmp/home"
state="$tmp/state"
mkdir -p "$home/.config/systemd/user" "$state"
# The Linux branch only restarts when the unit exists.
touch "$home/.config/systemd/user/opencode-server.service"

cat >"$tmp/opencode" <<'SH'
#!/bin/bash
state="$FAKE_OC_STATE"
case "${1:-} ${2:-}" in
  "service get")
    case "${3:-}" in
      port) [[ -f $state/port ]] && cat "$state/port" ;;
      hostname) [[ -f $state/hostname ]] && cat "$state/hostname" ;;
      disabled) : ;;
    esac
    ;;
  "service set")
    printf '%s' "${4:-}" >"$state/${3:-}"
    printf 'set %s %s\n' "${3:-}" "${4:-}" >>"$state/calls"
    ;;
  "service status")
    cat "$state/status"
    ;;
  "service restart")
    printf 'restart\n' >>"$state/calls"
    printf 'http://0.0.0.0:15001' >"$state/status"
    ;;
  "service unset")
    printf 'unset %s %s\n' "${3:-}" "${4:-}" >>"$state/calls"
    ;;
esac
exit 0
SH
chmod +x "$tmp/opencode"

out=""
status=0

run_install() {
  local os="${1:-Linux}"
  : >"$state/calls"
  mkdir -p "$tmp/bin"
  cat >"$tmp/bin/uname" <<SH
#!/bin/bash
printf '%s\n' "$os"
SH
  chmod +x "$tmp/bin/uname"
  HOME="$home" \
    OPENCODE_BIN="$tmp/opencode" \
    FAKE_OC_STATE="$state" \
    DOTFILES_SKIP_SHELL_RC=1 \
    PATH="$tmp/bin:$PATH" \
    bash "$INSTALL" --dry-run >"$tmp/out" 2>&1
  status=$?
  out="$(cat "$tmp/out")"
}

# --- 1. unset port is provisioned ---------------------------------------
printf 'http://127.0.0.1:49374' >"$state/status"
rm -f "$state/port" "$state/hostname"
run_install Linux
assert_status 0 "$status" "dry-run exits 0"
assert_contains "$out" "service set port 15001" "writes port 15001 when unset"
assert_contains "$out" "service set hostname 0.0.0.0" "writes hostname when unset"
assert_contains "$out" "service is http://127.0.0.1:49374, expected 0.0.0.0:15001; restarting" \
  "reports drift against the running port"
assert_contains "$out" "systemctl --user daemon-reload" "reloads systemd before restart"
assert_contains "$out" "systemctl --user restart opencode-server.service" "restarts the unit"

# --- 2. provisioned and running on 15001: no drift ----------------------
printf '15001' >"$state/port"
printf '0.0.0.0' >"$state/hostname"
printf 'http://0.0.0.0:15001' >"$state/status"
run_install Linux
assert_status 0 "$status" "healthy dry-run exits 0"
assert_contains "$out" "service port already 15001" "leaves a correct port alone"
assert_not_contains "$out" "expected 0.0.0.0:15001; restarting" "no drift when the service is on 0.0.0.0:15001"

# --- 2b. right port, loopback bind: drift -------------------------------
printf 'http://127.0.0.1:15001' >"$state/status"
run_install Linux
assert_contains "$out" "service is http://127.0.0.1:15001, expected 0.0.0.0:15001; restarting" \
  "a loopback bind on the right port is still drift"
assert_contains "$out" "$tmp/opencode service stop" "drops a client-started service before restarting"

# --- 3. macOS restarts the managed service, not a unit -------------------
printf 'http://127.0.0.1:49374' >"$state/status"
run_install Darwin
assert_status 0 "$status" "macOS dry-run exits 0"
assert_contains "$out" "service is http://127.0.0.1:49374, expected 0.0.0.0:15001; restarting" \
  "macOS reports drift"
assert_contains "$out" "$tmp/opencode service stop" "macOS stops the managed service"
assert_contains "$out" "$tmp/opencode service start" "macOS starts the managed service"
assert_not_contains "$out" "systemctl" "macOS never calls systemctl"
