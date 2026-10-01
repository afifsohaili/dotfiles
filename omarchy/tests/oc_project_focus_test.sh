#!/bin/bash

# Unit tests for `oc-project focus <dir>`.
#
# Covers: matching window focused (exit 0 + address on stdout + dispatch),
# no match (exit 3, quiet), several non-matching opencode clients,
# non-opencode windows ignored, missing/unreadable children or cmdline
# tolerated, cmdline with no --dir, the correct client focused among many,
# trailing-slash / `.` / symlink canonicalisation, malformed hyprctl JSON,
# empty client list, and a failing jq.
#
# Fixtures: a fake `hyprctl` (prints a clients JSON file for `clients -j`,
# records `dispatch ...` to a log) and an injected `OC_PROJECT_PROC_ROOT`
# tree: `$PROC/<pid>/task/<pid>/children` and `$PROC/<child>/cmdline`.

set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

SCRIPT="$HERE/../bin/oc-project"

if [[ ! -x $SCRIPT ]]; then
  fail "oc-project is not executable at $SCRIPT"
fi

tmp="$(make_fixture_dir)"
fakebin="$tmp/bin"
mkdir -p "$fakebin" "$tmp/dirs"

# --- fake hyprctl --------------------------------------------------------
cat >"$fakebin/hyprctl" <<'SH'
#!/bin/bash
log="${FAKE_HYPRCTL_LOG:?}"
if [[ ${1:-} == clients ]]; then
  exec cat "${FAKE_HYPRCTL_JSON:?}"
fi
if [[ ${1:-} == dispatch ]]; then
  shift
  printf '%s\n' "$*" >>"$log"
  if [[ -n ${FAKE_HYPRCTL_PRIMARY_FAIL:-} && "$*" == *hl.dsp.focus* ]]; then
    exit 1
  fi
  exit 0
fi
exit 1
SH
chmod +x "$fakebin/hyprctl"

# --- fixture helpers -----------------------------------------------------

new_case() {
  local name="$1"
  case_dir="$tmp/case-$name"
  proc="$case_dir/proc"
  dispatch_log="$case_dir/dispatch.log"
  json_file="$case_dir/clients.json"
  stderr_file="$case_dir/stderr"
  mkdir -p "$proc" "$case_dir"
  : >"$dispatch_log"
  printf '[]' >"$json_file"
}

add_child() {
  local parent="$1" child="$2"
  mkdir -p "$proc/$parent/task/$parent"
  printf '%s\n' "$child" >>"$proc/$parent/task/$parent/children"
}

set_cmdline() {
  local pid="$1"
  shift
  mkdir -p "$proc/$pid"
  : >"$proc/$pid/cmdline"
  local arg
  for arg in "$@"; do
    printf '%s\0' "$arg" >>"$proc/$pid/cmdline"
  done
}

add_client() {
  local pid="$1" addr="$2" class="$3"
  jq -c --arg pid "$pid" --arg addr "$addr" --arg class "$class" \
    '. + [{pid: ($pid | tonumber), address: $addr, class: $class}]' \
    "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"
}

run_focus() {
  FOCUS_OUT="$(OC_PROJECT_HYPRCTL="$fakebin/hyprctl" \
    FAKE_HYPRCTL_LOG="$dispatch_log" \
    FAKE_HYPRCTL_JSON="$json_file" \
    OC_PROJECT_PROC_ROOT="$proc" \
    "$SCRIPT" focus "$1" 2>"$stderr_file")"
  FOCUS_STATUS=$?
  FOCUS_ERR="$(cat "$stderr_file")"
}

dir() {
  local name="$1"
  mkdir -p "$tmp/dirs/$name"
  printf '%s\n' "$(readlink -f "$tmp/dirs/$name")"
}

# --- 1. matching window: exit 0, address out, dispatch called ------------
new_case match
target="$(dir target)"
other="$(dir other)"
add_child 100 200
set_cmdline 200 opencode attach http://127.0.0.1:15001 --dir "$target" --continue
add_client 100 0xabc01 org.omarchy.opencode
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "matching window exits 0"
assert_eq "0xabc01" "$FOCUS_OUT" "matching window prints address"
assert_contains "$(cat "$dispatch_log")" "address:0xabc01" "matching window dispatches focus"
assert_eq "" "$FOCUS_ERR" "matching window is quiet on stderr"

# --- 2. no matching window among several --------------------------------
new_case nomatch
add_child 100 200
set_cmdline 200 opencode attach --dir "$other"
add_child 300 400
set_cmdline 400 opencode attach --dir "$(dir another)"
add_client 100 0xaaa02 org.omarchy.opencode
add_client 300 0xbbb02 org.omarchy.opencode
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "no matching window exits 3"
assert_eq "" "$FOCUS_OUT" "no matching window writes no stdout"
assert_eq "" "$(cat "$dispatch_log")" "no matching window never dispatches"

# --- 3. non-opencode windows ignored even with a matching --dir ----------
new_case nonopencode
add_child 500 501
set_cmdline 501 foot --dir "$target"
add_client 500 0xccc03 org.omarchy.terminal
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "non-opencode window is ignored (exit 3)"
assert_eq "" "$FOCUS_OUT" "non-opencode window writes no stdout"
assert_eq "" "$(cat "$dispatch_log")" "non-opencode window never dispatches"

# --- 4. missing / unreadable children and cmdline are tolerated ----------
new_case unreadable
# client 600: no children file at all
add_client 600 0xddd04 org.omarchy.opencode
# client 700: child 701 exists but has no cmdline
add_child 700 701
add_client 700 0xeee04 org.omarchy.opencode
# client 800: child 801 cmdline exists but is unreadable
add_child 800 801
set_cmdline 801 opencode attach --dir "$target"
chmod 000 "$proc/801/cmdline"
add_client 800 0xfff04 org.omarchy.opencode
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "unreadable/missing proc entries are no-match (exit 3)"
assert_eq "" "$FOCUS_OUT" "unreadable/missing proc entries write no stdout"
assert_eq "" "$(cat "$dispatch_log")" "unreadable/missing proc entries never dispatch"

# --- 5. child cmdline without --dir --------------------------------------
new_case nodir
add_child 900 901
set_cmdline 901 opencode attach http://127.0.0.1:15001 --continue
add_client 900 0x11105 org.omarchy.opencode
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "cmdline without --dir exits 3"
assert_eq "" "$FOCUS_OUT" "cmdline without --dir writes no stdout"

# --- 6. several opencode clients, only one matches -----------------------
new_case oneofmany
add_child 1100 1101
set_cmdline 1101 opencode attach --dir "$other"
add_child 1200 1201
set_cmdline 1201 opencode attach --dir "$target"
add_client 1100 0x22206 org.omarchy.opencode
add_client 1200 0x33306 org.omarchy.opencode
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "one matching client among many exits 0"
assert_eq "0x33306" "$FOCUS_OUT" "only the matching client's address is printed"
assert_contains "$(cat "$dispatch_log")" "address:0x33306" "matching client is focused"
assert_not_contains "$(cat "$dispatch_log")" "address:0x22206" "non-matching client is not focused"

# --- 7. canonicalisation: trailing slash, `.`, symlink -------------------
new_case canonical
ln -s "$target" "$tmp/dirs/link"
add_child 1300 1301
set_cmdline 1301 opencode attach --dir "$target/." --continue
add_child 1400 1401
# client 1400's cmdline uses the symlink; target passed with a trailing slash
set_cmdline 1401 opencode attach --dir "$tmp/dirs/link"
add_client 1300 0x44407 org.omarchy.opencode
add_client 1400 0x55507 org.omarchy.opencode
run_focus "$target/"
assert_status 0 "$FOCUS_STATUS" "trailing slash / . / symlink still match (exit 0)"
assert_eq "0x44407" "$FOCUS_OUT" "first canonical match wins"
assert_contains "$(cat "$dispatch_log")" "address:0x44407" "canonical match is focused"

# --- 8. malformed hyprctl JSON -------------------------------------------
new_case malformed
printf 'this is not json' >"$json_file"
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "malformed JSON exits 3"
assert_eq "" "$FOCUS_OUT" "malformed JSON writes no stdout"
assert_eq "" "$(cat "$dispatch_log")" "malformed JSON never dispatches"

# --- 9. empty client list -------------------------------------------------
new_case empty
run_focus "$target"
assert_status 3 "$FOCUS_STATUS" "empty client list exits 3"
assert_eq "" "$FOCUS_OUT" "empty client list writes no stdout"

# --- 10. failing jq is tolerated -----------------------------------------
new_case jqfails
mkdir -p "$tmp/badjq"
cat >"$tmp/badjq/jq" <<'SH'
#!/bin/bash
exit 1
SH
chmod +x "$tmp/badjq/jq"
add_child 1500 1501
set_cmdline 1501 opencode attach --dir "$target"
add_client 1500 0x66610 org.omarchy.opencode
FOCUS_OUT="$(PATH="$tmp/badjq:$PATH" OC_PROJECT_HYPRCTL="$fakebin/hyprctl" \
  FAKE_HYPRCTL_LOG="$dispatch_log" FAKE_HYPRCTL_JSON="$json_file" \
  OC_PROJECT_PROC_ROOT="$proc" "$SCRIPT" focus "$target" 2>"$stderr_file")"
FOCUS_STATUS=$?
assert_status 3 "$FOCUS_STATUS" "failing jq is tolerated (exit 3)"
assert_eq "" "$FOCUS_OUT" "failing jq writes no stdout"

# --- 11. fallback dispatch form when the primary fails -------------------
new_case fallback
add_child 1600 1601
set_cmdline 1601 opencode attach --dir "$target"
add_client 1600 0x77711 org.omarchy.opencode
FOCUS_OUT="$(OC_PROJECT_HYPRCTL="$fakebin/hyprctl" \
  FAKE_HYPRCTL_LOG="$dispatch_log" FAKE_HYPRCTL_JSON="$json_file" \
  FAKE_HYPRCTL_PRIMARY_FAIL=1 OC_PROJECT_PROC_ROOT="$proc" \
  "$SCRIPT" focus "$target" 2>"$stderr_file")"
FOCUS_STATUS=$?
assert_status 0 "$FOCUS_STATUS" "fallback dispatch still exits 0"
assert_eq "0x77711" "$FOCUS_OUT" "fallback dispatch prints address"
assert_contains "$(cat "$dispatch_log")" "hl.dsp.focus" "primary dispatch form attempted first"
assert_contains "$(cat "$dispatch_log")" "focuswindow address:0x77711" "fallback focuswindow used"
