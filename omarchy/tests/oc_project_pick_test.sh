#!/bin/bash

# Unit tests for `oc-project pick` (and the no-subcommand default).
#
# Covers: preset dir row canonicalisation, Other… → menu-input chaining,
# `~` expansion, relative paths resolved against $PWD, nonexistent path,
# file-not-dir, cancel at select, cancel at input, empty input, a directory
# literally named `Other…` vs the Other… sentinel, and the prepended Other row.
#
# The menu commands are faked on PATH/through the env seams. Each fake reads
# rows on stdin exactly as the real `omarchy-menu-select` batch mode does.

set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

SCRIPT="$HERE/../bin/oc-project"

if [[ ! -x $SCRIPT ]]; then
  fail "oc-project is not executable at $SCRIPT"
fi

tmp="$(make_fixture_dir)"
projects="$tmp/projects"
home="$tmp/home"
workdir="$tmp/work"
bindir="$tmp/bin"

mkdir -p "$projects/gamma" "$projects/Other…" "$home/foo" "$workdir/sub" "$bindir"
: >"$projects/afile.txt"

real_gamma="$(readlink -f "$projects/gamma")"
real_other_dir="$(readlink -f "$projects/Other…")"
real_home_foo="$(readlink -f "$home/foo")"
real_rel_sub="$(readlink -f "$workdir/sub")"

# --- fakes ---------------------------------------------------------------

cat >"$bindir/fake-select" <<'SH'
#!/bin/bash
# Args: <prompt>. Reads rows on stdin, mirrors omarchy-menu-select's returned
# contract (Menu.qml:526-528,726): drop the glyph column; if a subtext
# remains return `label<TAB>subtext`, else return the bare label.
prompt="${1:-}"
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
    rest="${row#*$'\t'}"        # drop the leading glyph column
    label="${rest%%$'\t'*}"
    if [[ $rest == *$'\t'* ]]; then
      detail="${rest#*$'\t'}"
    else
      detail=""
    fi
    if [[ -n $detail ]]; then
      printf '%s\t%s\n' "$label" "$detail"
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
prompt="${1:-}"
if [[ -n ${FAKE_INPUT_EXIT:-} ]]; then
  exit "$FAKE_INPUT_EXIT"
fi
printf '%s\n' "${FAKE_INPUT_TEXT:-}"
SH

cat >"$bindir/omarchy-notification-send" <<'SH'
#!/bin/bash
exit 0
SH

chmod +x "$bindir/fake-select" "$bindir/fake-input" "$bindir/omarchy-notification-send"

export OC_PROJECT_OPENCODE_DB="$tmp/does-not-exist.db"
export OC_PROJECT_PROJECTS_DIR="$projects"
export OC_PROJECT_MENU_SELECT="$bindir/fake-select"
export OC_PROJECT_MENU_INPUT="$bindir/fake-input"
export PATH="$bindir:$PATH"

# --- helpers -------------------------------------------------------------

run_pick() {
  local sub="${1:-pick}"
  PICK_OUT="$("$SCRIPT" "$sub" 2>"$tmp/stderr")"
  PICK_STATUS=$?
  PICK_ERR="$(cat "$tmp/stderr")"
}

# --- 1. preset dir row is returned canonical -----------------------------
FAKE_SELECT_MATCH="$projects/gamma" run_pick
assert_status 0 "$PICK_STATUS" "preset pick exits 0"
assert_eq "$real_gamma" "$PICK_OUT" "preset pick returns canonical path"

# --- 2. Other… is prepended as the first row -----------------------------
other_capture="$tmp/rows"
FAKE_SELECT_CAPTURE="$other_capture" FAKE_SELECT_MATCH="Other…" \
  FAKE_INPUT_TEXT="$projects/gamma" run_pick
assert_status 0 "$PICK_STATUS" "Other flow exits 0"
first_row="$(head -n1 "$other_capture")"
assert_eq "$(printf '\tOther…\t')" "$first_row" "Other… row is prepended first"
assert_eq "$real_gamma" "$PICK_OUT" "Other… chains to input and returns typed path"

# --- 3. ~ expands to $HOME ----------------------------------------------
HOME="$home" FAKE_SELECT_MATCH="Other…" FAKE_INPUT_TEXT="~/foo" run_pick
assert_status 0 "$PICK_STATUS" "~/foo pick exits 0"
assert_eq "$real_home_foo" "$PICK_OUT" "~/foo expands to \$HOME/foo"

# --- 4. relative path resolves against $PWD ------------------------------
(
  cd "$workdir" || exit 1
  FAKE_SELECT_MATCH="Other…" FAKE_INPUT_TEXT="sub" "$SCRIPT" pick
) >"$tmp/out" 2>"$tmp/err"
rel_status=$?
assert_status 0 "$rel_status" "relative pick exits 0"
assert_eq "$real_rel_sub" "$(cat "$tmp/out")" "relative path resolves against \$PWD"

# --- 5. nonexistent path fails, no stdout, error on stderr ---------------
FAKE_SELECT_MATCH="Other…" FAKE_INPUT_TEXT="$tmp/nope/missing" run_pick
assert_status 1 "$PICK_STATUS" "nonexistent path exits non-zero"
assert_eq "" "$PICK_OUT" "nonexistent path writes no stdout"
assert_contains "$PICK_ERR" "missing" "nonexistent path reports on stderr"

# --- 6. a file (not a dir) fails -----------------------------------------
FAKE_SELECT_MATCH="Other…" FAKE_INPUT_TEXT="$projects/afile.txt" run_pick
assert_status 1 "$PICK_STATUS" "file path exits non-zero"
assert_eq "" "$PICK_OUT" "file path writes no stdout"

# --- 7. cancel at select: quiet non-zero ---------------------------------
FAKE_SELECT_EXIT=3 run_pick
assert_status 3 "$PICK_STATUS" "cancel at select propagates non-zero"
assert_eq "" "$PICK_OUT" "cancel at select writes no stdout"
assert_eq "" "$PICK_ERR" "cancel at select is quiet"

# --- 8. cancel at input: quiet non-zero ----------------------------------
FAKE_SELECT_MATCH="Other…" FAKE_INPUT_EXIT=3 run_pick
assert_status 3 "$PICK_STATUS" "cancel at input propagates non-zero"
assert_eq "" "$PICK_OUT" "cancel at input writes no stdout"
assert_eq "" "$PICK_ERR" "cancel at input is quiet"

# --- 9. empty input fails -------------------------------------------------
FAKE_SELECT_MATCH="Other…" FAKE_INPUT_TEXT="" run_pick
assert_status 1 "$PICK_STATUS" "empty input exits non-zero"
assert_eq "" "$PICK_OUT" "empty input writes no stdout"

# --- 10. a dir literally named Other… is not the sentinel ----------------
FAKE_SELECT_MATCH="$projects/Other…" run_pick
assert_status 0 "$PICK_STATUS" "dir named Other… exits 0"
assert_eq "$real_other_dir" "$PICK_OUT" "dir named Other… returns its own path"

# --- 11. no subcommand defaults to pick ----------------------------------
FAKE_SELECT_MATCH="$projects/gamma" run_pick ""
assert_status 0 "$PICK_STATUS" "no subcommand defaults to pick"
assert_eq "$real_gamma" "$PICK_OUT" "no subcommand returns picked path"
