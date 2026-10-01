#!/bin/bash

# Unit tests for `oc-project list`.
#
# Covers: ordering (recent DB first), dedupe by canonical path, dropping
# nonexistent DB paths, tolerating a missing DB, tolerating a missing
# Projects dir, skipping hidden dirs, exact menu row format, empty result.

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
elsewhere="$tmp/elsewhere"
mkdir -p "$projects" "$elsewhere"

# --- fixture directories -------------------------------------------------
mkdir -p "$projects/alpha" "$projects/beta" "$projects/.hidden" "$elsewhere/zeta"
: >"$projects/notdir.txt"

real_alpha="$(readlink -f "$projects/alpha")"
real_beta="$(readlink -f "$projects/beta")"
real_zeta="$(readlink -f "$elsewhere/zeta")"

# --- fixture opencode DB -------------------------------------------------
db="$tmp/opencode.db"
sqlite3 "$db" <<SQL
CREATE TABLE project (
  id text PRIMARY KEY,
  worktree text NOT NULL,
  time_updated integer NOT NULL
);
CREATE TABLE project_directory (
  project_id text NOT NULL,
  directory text NOT NULL
);
INSERT INTO project VALUES ('p_zeta',  '', 3000);
INSERT INTO project VALUES ('p_alpha', '', 2000);
INSERT INTO project VALUES ('p_stale', '', 1000);
INSERT INTO project_directory VALUES ('p_zeta',  '$elsewhere/zeta');
INSERT INTO project_directory VALUES ('p_alpha', '$projects/alpha');
INSERT INTO project_directory VALUES ('p_stale', '$elsewhere/nope');
SQL

# --- helpers -------------------------------------------------------------
# Default fixture env; individual blocks override with a var prefix.
export OC_PROJECT_OPENCODE_DB="$db"
export OC_PROJECT_PROJECTS_DIR="$projects"

run_list() {
  LIST_OUT="$("$SCRIPT" list 2>"$tmp/stderr")"
  LIST_STATUS=$?
  LIST_ERR="$(cat "$tmp/stderr")"
  if [[ -z $LIST_OUT ]]; then
    ROWS=()
  else
    mapfile -t ROWS <<<"$LIST_OUT"
  fi
}

row_matching() {
  local needle="$1" row
  for row in "${ROWS[@]:-}"; do
    if [[ $row == *"$needle"* ]]; then
      printf '%s\n' "$row"
      return 0
    fi
  done
  return 1
}

count_matching() {
  local needle="$1" row count=0
  for row in "${ROWS[@]:-}"; do
    [[ $row == *"$needle"* ]] && count=$(( count + 1 ))
  done
  printf '%d\n' "$count"
}

# --- 1. ordering: recent DB dir before Projects-only dir -----------------
run_list
assert_status 0 "$LIST_STATUS" "list exits 0 with full fixture"
assert_eq "$real_zeta" "$(printf '%s' "${ROWS[0]:-}" | cut -f3)" "recent DB dir is first"
assert_eq "$real_alpha" "$(printf '%s' "${ROWS[1]:-}" | cut -f3)" "deduped DB dir keeps its position"
assert_eq "$real_beta" "$(printf '%s' "${ROWS[2]:-}" | cut -f3)" "Projects-only dir is last"

# --- 2. dedupe: alpha appears exactly once -------------------------------
assert_eq "1" "$(count_matching "$real_alpha")" "alpha appears once despite two sources"

# --- 3. nonexistent DB path dropped --------------------------------------
assert_not_contains "$LIST_OUT" "nope" "nonexistent DB path is dropped"

# --- 4. exact row format -------------------------------------------------
alpha_row="$(row_matching "$real_alpha")"
assert_eq "$(printf '\talpha\t%s' "$real_alpha")" "$alpha_row" "row is TAB basename TAB abs path"

# --- 5. hidden dirs skipped ----------------------------------------------
assert_not_contains "$LIST_OUT" ".hidden" "hidden dir under Projects is skipped"
assert_not_contains "$LIST_OUT" "notdir.txt" "non-directory entries are skipped"

# --- 5b. hidden dirs from the DB are skipped too -------------------------
mkdir -p "$elsewhere/.secret"
sqlite3 "$db" "INSERT INTO project VALUES ('p_secret', '', 4000);
INSERT INTO project_directory VALUES ('p_secret', '$elsewhere/.secret');"
run_list
assert_status 0 "$LIST_STATUS" "hidden DB dir fixture still exits 0"
assert_not_contains "$LIST_OUT" ".secret" "hidden dir from DB is skipped"

# --- 6. missing DB tolerated ---------------------------------------------
OC_PROJECT_OPENCODE_DB="$tmp/does-not-exist.db" \
  OC_PROJECT_PROJECTS_DIR="$projects" \
  run_list
assert_status 0 "$LIST_STATUS" "missing DB is tolerated (exit 0)"
assert_contains "$LIST_OUT" "$real_alpha" "missing DB still lists Projects dirs"
assert_contains "$LIST_OUT" "$real_beta" "missing DB still lists Projects dirs"
assert_not_contains "$LIST_OUT" "zeta" "missing DB lists no DB dirs"

# --- 7. missing Projects dir tolerated -----------------------------------
OC_PROJECT_OPENCODE_DB="$db" \
  OC_PROJECT_PROJECTS_DIR="$tmp/does-not-exist" \
  run_list
assert_status 0 "$LIST_STATUS" "missing Projects dir is tolerated (exit 0)"
assert_contains "$LIST_OUT" "$real_zeta" "missing Projects dir still lists DB dirs"
assert_contains "$LIST_OUT" "$real_alpha" "missing Projects dir still lists DB dirs"
assert_not_contains "$LIST_OUT" "$real_beta" "missing Projects dir lists no Projects-only dirs"

# --- 8. empty result -----------------------------------------------------
empty_projects="$tmp/empty-projects"
mkdir -p "$empty_projects"
OC_PROJECT_OPENCODE_DB="$tmp/does-not-exist.db" \
  OC_PROJECT_PROJECTS_DIR="$empty_projects" \
  run_list
assert_status 0 "$LIST_STATUS" "empty result exits 0"
assert_eq "" "$LIST_OUT" "empty result writes no stdout"
