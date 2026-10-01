#!/bin/bash

# Phase 5 review regression test: the real /proc/<pid>/task/<pid>/children
# format.
#
# The kernel writes the children as space-separated pids on a single line with
# a trailing space and NO trailing newline, e.g. `200 ` or `100 200 `. The
# other focus/feature tests write one child per line with `printf '%s\n'`, so
# they never exercise the real bytes. This file pins the real format.
#
# Case 1: single child, trailing space, no newline -> must match (exit 0,
#         address on stdout, dispatch called).
# Case 2: two children space-separated on one line -> the second child matches.
#
# These are the exact bytes `cat /proc/<pid>/task/<pid>/children` produces on
# this machine.

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

cat >"$fakebin/hyprctl" <<'SH'
#!/bin/bash
if [[ ${1:-} == clients ]]; then
  exec cat "${FAKE_HYPRCTL_JSON:?}"
fi
if [[ ${1:-} == dispatch ]]; then
  shift
  printf '%s\n' "$*" >>"${FAKE_HYPRCTL_LOG:?}"
  exit 0
fi
exit 1
SH
chmod +x "$fakebin/hyprctl"

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

add_client() {
  local pid="$1" addr="$2"
  jq -c --arg pid "$pid" --arg addr "$addr" \
    '. + [{pid: ($pid | tonumber), address: $addr, class: "org.omarchy.opencode"}]' \
    "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"
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

run_focus() {
  FOCUS_OUT="$(OC_PROJECT_HYPRCTL="$fakebin/hyprctl" \
    FAKE_HYPRCTL_LOG="$dispatch_log" \
    FAKE_HYPRCTL_JSON="$json_file" \
    OC_PROJECT_PROC_ROOT="$proc" \
    "$SCRIPT" focus "$1" 2>"$stderr_file")"
  FOCUS_STATUS=$?
}

dir() {
  local name="$1"
  mkdir -p "$tmp/dirs/$name"
  printf '%s\n' "$(readlink -f "$tmp/dirs/$name")"
}

target="$(dir target)"

# --- 1. single child, trailing space, no newline (real kernel format) -----
new_case single_real_format
mkdir -p "$proc/100/task/100" "$proc/200"
# Exact kernel bytes: pid, a space, and no newline.
printf '200 ' >"$proc/100/task/100/children"
set_cmdline 200 opencode attach http://127.0.0.1:15001 --dir "$target" --continue
add_client 100 0xabc01
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "real children format (single, no newline) exits 0"
assert_eq "0xabc01" "$FOCUS_OUT" "real children format (single, no newline) prints address"
assert_contains "$(cat "$dispatch_log")" "address:0xabc01" "real children format (single, no newline) focuses window"

# --- 2. multiple children, space-separated on one line --------------------
new_case multiple_real_format
mkdir -p "$proc/300/task/300" "$proc/301" "$proc/302"
other="$(dir other)"
# Child 301 does not match; child 302 does.
printf '301 302 ' >"$proc/300/task/300/children"
set_cmdline 301 opencode attach --dir "$other"
set_cmdline 302 opencode attach --dir "$target"
add_client 300 0xdef02
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "real children format (multiple, space-separated) exits 0"
assert_eq "0xdef02" "$FOCUS_OUT" "real children format (multiple) prints matching address"
assert_contains "$(cat "$dispatch_log")" "address:0xdef02" "real children format (multiple) focuses window"

# --- 3. a null-pid client does not abort the walk (tolerated) --------------
new_case null_pid
mkdir -p "$proc/400/task/400" "$proc/401" "$proc/500/task/500" "$proc/501"
printf '401 ' >"$proc/400/task/400/children"
set_cmdline 401 opencode attach --dir "$other"
printf '501 ' >"$proc/500/task/500/children"
set_cmdline 501 opencode attach --dir "$target"
# First entry has a null pid; a later valid client still has to match.
printf '[{"pid":null,"address":"0xnull","class":"org.omarchy.opencode"}]' >"$json_file"
add_client 500 0xaaa03
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "null-pid client is skipped, later match still exits 0"
assert_eq "0xaaa03" "$FOCUS_OUT" "null-pid client does not abort the walk"

# --- 4. a client with no children file does not abort the walk ------------
new_case missing_children
mkdir -p "$proc/600/task/600" "$proc/700/task/700" "$proc/701"
# Client 600 has a task dir but no children file; client 700 matches.
printf '701 ' >"$proc/700/task/700/children"
set_cmdline 701 opencode attach --dir "$target"
add_client 600 0xbbb03
add_client 700 0xccc03
run_focus "$target"
assert_status 0 "$FOCUS_STATUS" "client without children file is tolerated"
assert_eq "0xccc03" "$FOCUS_OUT" "a later matching client is still found"

# --- 5. picker rows are not piped into the menu ---------------------------
# Under `pipefail`, a menu that exits before consuming every row would SIGPIPE
# the row writer and surface 141 instead of the menu's own status. The picker
# must feed rows through a redirection, not a pipe. This menu exits 0 early
# and ignores stdin entirely, then prints a selection; the pick must succeed.
new_case pick_no_sigpipe
sink="$case_dir/sink"
cat >"$fakebin/menu-early-exit" <<'SH'
#!/bin/bash
# Deliberately do not read stdin, then return a valid selection.
printf 'proj\t%s\n' "${PICK_DIR:?}"
SH
chmod +x "$fakebin/menu-early-exit"
mkdir -p "$tmp/dirs/proj"
proj_canon="$(readlink -f "$tmp/dirs/proj")"
PICK_OUT="$(OC_PROJECT_MENU_SELECT="$fakebin/menu-early-exit" \
  PICK_DIR="$proj_canon" \
  OC_PROJECT_PROJECTS_DIR="$tmp/dirs" \
  OC_PROJECT_OPENCODE_DB="$case_dir/none.db" \
  "$SCRIPT" pick 2>"$stderr_file")"
PICK_STATUS=$?
assert_status 0 "$PICK_STATUS" "picker survives a menu that ignores stdin"
assert_eq "$proj_canon" "$PICK_OUT" "picker still resolves the selection"
