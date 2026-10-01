#!/bin/bash

# Feature (end-to-end) test for the wired `oc-project` default flow.
#
# Wires every seam to fakes and exercises the whole contract twice, plus a
# real `list`-path check to prove rows flow into the picker.
#
#   1. Directory already open: `hyprctl` reports an opencode window whose
#      opencode child has `--dir <dir>`; the flow must focus it (dispatch
#      recorded), exit 0, and never launch.
#   2. Directory not open: no matching window; the flow must exit 0, launch
#      with `--title=oc: <dir>` and `oc <dir>`, and app-id
#      `org.omarchy.opencode`.
#   3. Real list path: a fixture Projects dir feeds real rows into the picker.
#
# Seams faked: launcher, menu, hyprctl, proc root. The real `focus`
# implementation runs against the fake hyprctl + fixture /proc tree.

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
projects="$tmp/projects"
proc="$tmp/proc"
mkdir -p "$fakebin" "$projects"
: >"$projects/afile.txt"
mkdir -p "$projects/proj"

real_proj="$(readlink -f "$projects/proj")"

# --- fake launcher: records argv, one element per line -------------------
cat >"$fakebin/xdg-terminal-exec" <<'SH'
#!/bin/bash
cap="${FAKE_LAUNCH_CAPTURE:?}"
: >"$cap"
for arg in "$@"; do
  printf '%s\n' "$arg" >>"$cap"
done
exit 0
SH
chmod +x "$fakebin/xdg-terminal-exec"

# --- fake hyprctl: serves a clients JSON, records dispatch ---------------
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

# --- fake menu: picks a directory row by substring -----------------------
cat >"$fakebin/omarchy-menu-select" <<'SH'
#!/bin/bash
mapfile -t rows
if [[ -n ${FAKE_SELECT_CAPTURE:-} ]]; then
  printf '%s\n' "${rows[@]}" >"$FAKE_SELECT_CAPTURE"
fi
needle="${FAKE_SELECT_MATCH:?}"
for row in "${rows[@]}"; do
  if [[ $row == *"$needle"* ]]; then
    rest="${row#*$'\t'}"
    label="${rest%%$'\t'*}"
    if [[ $rest == *$'\t'* ]]; then
      printf '%s\t%s\n' "$label" "${rest#*$'\t'}"
    else
      printf '%s\n' "$label"
    fi
    exit 0
  fi
done
exit 1
SH
cat >"$fakebin/omarchy-menu-input" <<'SH'
#!/bin/bash
printf '%s\n' "${FAKE_INPUT_TEXT:-}"
SH
chmod +x "$fakebin/omarchy-menu-select" "$fakebin/omarchy-menu-input"

# --- fixture proc tree: parent terminal pid -> opencode child ------------
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

# --- common env ----------------------------------------------------------
export HOME="$tmp/home"
export XDG_DATA_HOME="$tmp/home/.local/share"
mkdir -p "$HOME"
export OC_PROJECT_OPENCODE_DB="$tmp/does-not-exist.db"
export OC_PROJECT_PROJECTS_DIR="$projects"
export OC_PROJECT_PROC_ROOT="$proc"
export OC_PROJECT_MENU_SELECT="$fakebin/omarchy-menu-select"
export OC_PROJECT_MENU_INPUT="$fakebin/omarchy-menu-input"
export OC_PROJECT_HYPRCTL="$fakebin/hyprctl"
export OC_PROJECT_LAUNCH="$fakebin/xdg-terminal-exec"
export FAKE_LAUNCH_CAPTURE="$tmp/launch.argv"
export FAKE_HYPRCTL_JSON="$tmp/clients.json"
export FAKE_HYPRCTL_LOG="$tmp/dispatch.log"
export PATH="$fakebin:$PATH"

load_argv() {
  if [[ -s $FAKE_LAUNCH_CAPTURE ]]; then
    mapfile -t LAUNCH_ARGV <"$FAKE_LAUNCH_CAPTURE"
  else
    LAUNCH_ARGV=()
  fi
}

run_flow() {
  : >"$FAKE_LAUNCH_CAPTURE"
  : >"$FAKE_HYPRCTL_LOG"
  FLOW_OUT="$("$SCRIPT" 2>"$tmp/stderr")"
  FLOW_STATUS=$?
  FLOW_ERR="$(cat "$tmp/stderr")"
  load_argv
}

# =====================================================================
# 1. directory already open -> focus, no launch
# =====================================================================
: >"$FAKE_HYPRCTL_LOG"
printf '[]' >"$FAKE_HYPRCTL_JSON"

add_child 100 200
set_cmdline 200 opencode attach http://127.0.0.1:15001 --dir "$real_proj" --continue
jq -c -n '[{pid: 100, address: "0xabc01", class: "org.omarchy.opencode"}]' \
  >"$FAKE_HYPRCTL_JSON"

FAKE_SELECT_MATCH="$real_proj" run_flow
assert_status 0 "$FLOW_STATUS" "already-open dir: exits 0"
assert_eq "" "$FLOW_OUT" "already-open dir: writes no stdout"
assert_eq "" "$FLOW_ERR" "already-open dir: is quiet on stderr"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "already-open dir: never launches"
assert_contains "$(cat "$FAKE_HYPRCTL_LOG")" "address:0xabc01" \
  "already-open dir: focuses the matching window"

# =====================================================================
# 2. directory not open -> launch with exact argv
# =====================================================================
: >"$FAKE_HYPRCTL_LOG"
printf '[]' >"$FAKE_HYPRCTL_JSON"

FAKE_SELECT_MATCH="$real_proj" run_flow
assert_status 0 "$FLOW_STATUS" "not-open dir: exits 0"
assert_eq "4" "${#LAUNCH_ARGV[@]}" "not-open dir: launches four argv elements"
assert_eq "--app-id=org.omarchy.opencode" "${LAUNCH_ARGV[0]:-}" \
  "not-open dir: app-id is org.omarchy.opencode"
assert_eq "--title=oc: $real_proj" "${LAUNCH_ARGV[1]:-}" \
  "not-open dir: title is oc: <dir>"
assert_eq "oc" "${LAUNCH_ARGV[2]:-}" "not-open dir: command is oc"
assert_eq "$real_proj" "${LAUNCH_ARGV[3]:-}" "not-open dir: argument is the directory"
assert_eq "" "$(cat "$FAKE_HYPRCTL_LOG")" "not-open dir: never dispatches focus"

# =====================================================================
# 3. real list path: fixture Projects rows reach the picker
# =====================================================================
# No DB, Projects dir has one real subdir: `list` must emit exactly one row,
# and the picker must be handed it (after the Other… sentinel).
LIST_OUT="$("$SCRIPT" list 2>"$tmp/stderr")"
assert_status 0 "$?" "real list: exits 0"
assert_contains "$LIST_OUT" "$real_proj" "real list: emits the fixture dir row"

SELECT_CAPTURE="$tmp/rows"
: >"$FAKE_HYPRCTL_LOG"
printf '[]' >"$FAKE_HYPRCTL_JSON"
FAKE_SELECT_MATCH="$real_proj" FAKE_SELECT_CAPTURE="$SELECT_CAPTURE" run_flow
assert_status 0 "$FLOW_STATUS" "real list pick: exits 0"
assert_eq "$(printf '\tOther…\t')" "$(head -n1 "$SELECT_CAPTURE")" \
  "real list pick: Other… row is first"
assert_eq "$(printf '\tproj\t%s' "$real_proj")" "$(sed -n '2p' "$SELECT_CAPTURE")" \
  "real list pick: real dir row reaches the picker"
assert_eq "--title=oc: $real_proj" "${LAUNCH_ARGV[1]:-}" \
  "real list pick: launches the picked dir"
