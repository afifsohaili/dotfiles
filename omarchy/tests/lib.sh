# shellcheck shell=bash
# Minimal pure-bash assertion + fixture library for omarchy tests.
#
# Source this from a `*_test.sh` file. Each assertion prints one TAP-style
# `ok` / `not ok` line. At exit the library prints a per-file summary and
# forces a non-zero exit status if any assertion failed, so the runner only
# needs the script's exit code.
#
# Usage:
#   #!/bin/bash
#   source "$(dirname "$0")/lib.sh"
#   assert_eq "expected" "$actual" "message"
#   fixture=$(make_fixture_dir)
#   # ... traps clean fixtures automatically

_TEST_NAME="$(basename -- "${0:-test}")"
_ASSERT_COUNT=0
_ASSERT_FAILED=0
_FIXTURE_DIRS=()

# --------------------------------------------------------------- internals

_register_fixture() {
  _FIXTURE_DIRS+=("$1")
}

_cleanup_fixtures() {
  local dir
  for dir in "${_FIXTURE_DIRS[@]:-}"; do
    [[ -n $dir ]] && rm -rf -- "$dir"
  done
}

_exit_report() {
  local code=$?
  _cleanup_fixtures
  printf '# %s: %d assertion(s), %d failed\n' \
    "$_TEST_NAME" "$_ASSERT_COUNT" "$_ASSERT_FAILED"
  if (( _ASSERT_FAILED > 0 )); then
    exit 1
  fi
  exit "$code"
}
trap _exit_report EXIT

_pass() {
  _ASSERT_COUNT=$(( _ASSERT_COUNT + 1 ))
  printf 'ok - %s\n' "${1:-$_TEST_NAME assertion $_ASSERT_COUNT}"
}

_fail() {
  _ASSERT_COUNT=$(( _ASSERT_COUNT + 1 ))
  _ASSERT_FAILED=$(( _ASSERT_FAILED + 1 ))
  printf 'not ok - %s\n' "${1:-$_TEST_NAME assertion $_ASSERT_COUNT}"
}

# -------------------------------------------------------------- assertions

# fail <message> -> mark failure and abort the test file immediately.
fail() {
  _fail "${1:-$_TEST_NAME failed}"
  exit 1
}

# assert_eq <expected> <actual> [message]
assert_eq() {
  local expected="$1" actual="$2" msg="${3:-assertion $_ASSERT_COUNT: $1 == $2}"
  if [[ $expected == "$actual" ]]; then
    _pass "$msg"
  else
    _fail "$msg"
    printf '  expected: %s\n' "$(printf '%q' "$expected")"
    printf '  actual:   %s\n' "$(printf '%q' "$actual")"
  fi
}

# assert_contains <haystack> <needle> [message]
assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-assertion $_ASSERT_COUNT: contains $(printf '%q' "$needle")}"
  if [[ $haystack == *"$needle"* ]]; then
    _pass "$msg"
  else
    _fail "$msg"
    printf '  haystack: %s\n' "$(printf '%q' "$haystack")"
  fi
}

# assert_not_contains <haystack> <needle> [message]
assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-assertion $_ASSERT_COUNT: does not contain $(printf '%q' "$needle")}"
  if [[ $haystack != *"$needle"* ]]; then
    _pass "$msg"
  else
    _fail "$msg"
    printf '  haystack: %s\n' "$(printf '%q' "$haystack")"
  fi
}

# assert_status <expected> <actual> [message] -> compare an exit code.
assert_status() {
  local expected="$1" actual="$2" msg="${3:-assertion $_ASSERT_COUNT: status $1 == $2}"
  assert_eq "$expected" "$actual" "$msg"
}

# assertion_count -> total assertions so far on stdout.
assertion_count() {
  printf '%d\n' "$_ASSERT_COUNT"
}

# ---------------------------------------------------------------- fixtures

# make_fixture_dir -> print a fresh temp dir; removed on exit.
make_fixture_dir() {
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/omarchy-test.XXXXXX")"
  _register_fixture "$dir"
  printf '%s\n' "$dir"
}

# make_fixture_link <dir> -> register an existing dir for cleanup.
make_fixture_link() {
  _register_fixture "$1"
}
