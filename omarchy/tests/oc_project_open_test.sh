#!/bin/bash

# Unit tests for `oc-project open <dir>` and the wired default flow.
#
# Covers:
#   - `open` produces exactly the launcher argv the plan fixes
#     (`--app-id=`, `--title=oc: <abs>`, then `oc <abs>`).
#   - `open` on a nonexistent path or a file launches nothing.
#   - default flow: pick → focus0 => no launch;
#     pick → focus3 => launch; pick → focus-other => error, no launch;
#     cancel at pick => quiet non-zero, no launch.
#
# Seams faked here: the menu, the picker's focus step, the launcher.

set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

SCRIPT="$HERE/../bin/oc-project"

if [[ ! -x $SCRIPT ]]; then
  fail "oc-project is not executable at $SCRIPT"
fi

tmp="$(make_fixture_dir)"
bindir="$tmp/bin"
projects="$tmp/projects"
mkdir -p "$bindir" "$projects/proj"

real_proj="$(readlink -f "$projects/proj")"
: >"$projects/afile.txt"

# --- fakes ---------------------------------------------------------------

cat >"$bindir/fake-launch" <<'SH'
#!/bin/bash
cap="${FAKE_LAUNCH_CAPTURE:?}"
: >"$cap"
for arg in "$@"; do
  printf '%s\n' "$arg" >>"$cap"
done
exit "${FAKE_LAUNCH_EXIT:-0}"
SH

cat >"$bindir/fake-focus" <<'SH'
#!/bin/bash
exit "${FAKE_FOCUS_EXIT:-0}"
SH

cat >"$bindir/fake-select" <<'SH'
#!/bin/bash
mapfile -t rows
if [[ -n ${FAKE_SELECT_CAPTURE:-} ]]; then
  printf '%s\n' "${rows[@]}" >"$FAKE_SELECT_CAPTURE"
fi
if [[ -n ${FAKE_SELECT_EXIT:-} ]]; then
  exit "$FAKE_SELECT_EXIT"
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

cat >"$bindir/fake-input" <<'SH'
#!/bin/bash
printf '%s\n' "${FAKE_INPUT_TEXT:-}"
SH

chmod +x "$bindir/fake-launch" "$bindir/fake-focus" \
  "$bindir/fake-select" "$bindir/fake-input"

export OC_PROJECT_OPENCODE_DB="$tmp/does-not-exist.db"
export OC_PROJECT_PROJECTS_DIR="$projects"
export OC_PROJECT_MENU_SELECT="$bindir/fake-select"
export OC_PROJECT_MENU_INPUT="$bindir/fake-input"
export OC_PROJECT_LAUNCH="$bindir/fake-launch"
export OC_PROJECT_FOCUS="$bindir/fake-focus"
export FAKE_LAUNCH_CAPTURE="$tmp/launch.argv"
export PATH="$bindir:$PATH"

# --- helpers -------------------------------------------------------------

load_argv() {
  if [[ -s $FAKE_LAUNCH_CAPTURE ]]; then
    mapfile -t LAUNCH_ARGV <"$FAKE_LAUNCH_CAPTURE"
  else
    LAUNCH_ARGV=()
  fi
}

run_open() {
  : >"$FAKE_LAUNCH_CAPTURE"
  OPEN_OUT="$("$SCRIPT" open "$1" 2>"$tmp/stderr")"
  OPEN_STATUS=$?
  OPEN_ERR="$(cat "$tmp/stderr")"
  load_argv
}

run_default() {
  : >"$FAKE_LAUNCH_CAPTURE"
  DEFAULT_OUT="$("$SCRIPT" 2>"$tmp/stderr")"
  DEFAULT_STATUS=$?
  DEFAULT_ERR="$(cat "$tmp/stderr")"
  load_argv
}

# --- 1. open <dir> builds the exact launcher argv ------------------------

run_open "$projects/proj"
assert_status 0 "$OPEN_STATUS" "open <dir> exits 0"
assert_eq "4" "${#LAUNCH_ARGV[@]}" "open passes exactly four argv elements"
assert_eq "--app-id=org.omarchy.opencode" "${LAUNCH_ARGV[0]:-}" "argv[0] sets the window class"
assert_eq "--title=oc: $real_proj" "${LAUNCH_ARGV[1]:-}" "argv[1] sets the window title"
assert_eq "oc" "${LAUNCH_ARGV[2]:-}" "argv[2] is the oc command"
assert_eq "$real_proj" "${LAUNCH_ARGV[3]:-}" "argv[3] is the absolute directory"
assert_eq "" "$OPEN_ERR" "open is quiet on stderr"

# --- 2. open with a trailing slash canonicalises -------------------------

run_open "$projects/proj/"
assert_status 0 "$OPEN_STATUS" "open with trailing slash exits 0"
assert_eq "$real_proj" "${LAUNCH_ARGV[3]:-}" "open canonicalises the directory"

# --- 3. open <nonexistent> -> non-zero, no launch ------------------------

run_open "$tmp/nope/missing"
assert_status 1 "$OPEN_STATUS" "open nonexistent exits non-zero"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "open nonexistent launches nothing"
assert_contains "$OPEN_ERR" "missing" "open nonexistent reports on stderr"

# --- 4. open <file> -> non-zero, no launch -------------------------------

run_open "$projects/afile.txt"
assert_status 1 "$OPEN_STATUS" "open a file exits non-zero"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "open a file launches nothing"

# --- 5. open with no argument -> non-zero, no launch ---------------------

: >"$FAKE_LAUNCH_CAPTURE"
OPEN_OUT="$("$SCRIPT" open 2>"$tmp/stderr")"
OPEN_STATUS=$?
load_argv
assert_status 1 "$OPEN_STATUS" "open without a directory exits non-zero"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "open without a directory launches nothing"

# --- 6. default: pick -> focus 0 -> NO launch ----------------------------

FAKE_FOCUS_EXIT=0 FAKE_SELECT_MATCH="$projects/proj" run_default
assert_status 0 "$DEFAULT_STATUS" "default flow exits 0 when focus succeeds"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "default flow does not launch when focus succeeds"

# --- 7. default: pick -> focus 3 (not found) -> launch -------------------

FAKE_FOCUS_EXIT=3 FAKE_SELECT_MATCH="$projects/proj" run_default
assert_status 0 "$DEFAULT_STATUS" "default flow exits 0 after launching"
assert_eq "4" "${#LAUNCH_ARGV[@]}" "default flow launches exactly four argv elements"
assert_eq "--title=oc: $real_proj" "${LAUNCH_ARGV[1]:-}" "default launch has the expected title"
assert_eq "$real_proj" "${LAUNCH_ARGV[3]:-}" "default launch targets the picked directory"

# --- 8. default: pick -> focus other error -> non-zero, no launch --------

FAKE_FOCUS_EXIT=5 FAKE_SELECT_MATCH="$projects/proj" run_default
assert_status 5 "$DEFAULT_STATUS" "default flow propagates a focus error"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "default flow does not launch on a focus error"

# --- 9. default: cancel at pick -> quiet non-zero, no launch -------------

FAKE_SELECT_EXIT=3 run_default
assert_status 3 "$DEFAULT_STATUS" "default flow propagates a pick cancel"
assert_eq "" "$DEFAULT_OUT" "default flow writes no stdout on cancel"
assert_eq "" "$DEFAULT_ERR" "default flow is quiet on cancel"
assert_eq "0" "${#LAUNCH_ARGV[@]}" "default flow does not launch on cancel"
