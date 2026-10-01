#!/bin/bash

# Run every omarchy bash test file (*_test.sh) under this directory,
# recursively. No external dependencies: the tests are plain bash scripts
# that exit non-zero on failure and follow the assertion helpers in lib.sh.
#
# Usage:
#   omarchy/tests/run.sh [name-filter]
#
# Exits non-zero if any test file fails.

set -uo pipefail

TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

test_files=()
while IFS= read -r file; do
  [[ -n $file ]] && test_files+=("$file")
done < <(
  find "$TESTS_DIR" -type f -name '*_test.sh' \
    | LC_ALL=C sort
)

if (( ${#test_files[@]} == 0 )); then
  echo "# no *_test.sh files found in $TESTS_DIR"
  exit 0
fi

total=0
passed=0
failed=0
assertions=0
assertion_failures=0

for file in "${test_files[@]}"; do
  relative="${file#"$TESTS_DIR"/}"
  if [[ -n $FILTER && $relative != *"$FILTER"* ]]; then
    continue
  fi

  total=$(( total + 1 ))
  echo "# --- $relative ---"

  output="$(bash "$file" 2>&1)"
  status=$?
  printf '%s\n' "$output"

  # Tests print: "# <name>: N assertion(s), M failed".
  if [[ $output =~ :[[:space:]]*([0-9]+)[[:space:]]+assertion ]]; then
    assertions=$(( assertions + BASH_REMATCH[1] ))
  fi
  if [[ $output =~ ([0-9]+)[[:space:]]+failed ]]; then
    assertion_failures=$(( assertion_failures + BASH_REMATCH[1] ))
  fi

  if (( status == 0 )); then
    passed=$(( passed + 1 ))
    echo "ok - $relative"
  else
    failed=$(( failed + 1 ))
    echo "not ok - $relative (exit $status)"
  fi
done

echo "#"
echo "# ${total} test file(s): ${passed} passed, ${failed} failed"
echo "# ${assertions} assertion(s): $(( assertions - assertion_failures )) passed, ${assertion_failures} failed"

(( failed == 0 ))
