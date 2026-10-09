#!/bin/bash
# shellcheck shell=bash
#
# Covers omarchy/bin/omarchy-agent-usage-ollama against the metered /api/usage
# shape (totals + buckets over 24h/7d/30d). curl is shimmed; no network.
source "$(dirname "$0")/lib.sh"

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/bin/omarchy-agent-usage-ollama"

FIXTURE_HOME="$(make_fixture_dir)"
FIXTURE_CACHE="$(make_fixture_dir)"
FIXTURE_BIN="$(make_fixture_dir)"

mkdir -p "$FIXTURE_HOME/.local/share/opencode/secrets"
cat > "$FIXTURE_BIN/curl" <<'SHIM'
#!/bin/bash
cat "${FAKE_CURL_PAYLOAD:-/dev/null}"
printf '\n%s\n' "${FAKE_CURL_STATUS:-200}"
SHIM
chmod +x "$FIXTURE_BIN/curl"

# run_collector <payload-file> <status> [collector args...]
run_collector() {
  local payload="$1" status="$2"
  shift 2
  env -i \
    PATH="$FIXTURE_BIN:$PATH" \
    HOME="$FIXTURE_HOME" \
    XDG_CACHE_HOME="$FIXTURE_CACHE" \
    FAKE_CURL_PAYLOAD="$payload" \
    FAKE_CURL_STATUS="$status" \
    bash "$SCRIPT" "$@"
}

write_key() { printf '%s\n' "sk-test-key" > "$FIXTURE_HOME/.local/share/opencode/secrets/ollama_api_key"; }
remove_key() { rm -f "$FIXTURE_HOME/.local/share/opencode/secrets/ollama_api_key"; }
cache_file() { printf '%s\n' "$FIXTURE_CACHE/omarchy/agent-usage/ollama.json"; }

# make_payload <file> — two in-window daily buckets plus one out-of-window
# bucket that must be ignored: 500+0 and 400+100 tokens.
make_payload() {
  local file="$1" d1 d2
  d1="$(date -d 'today - 6 days' +%F)"
  d2="$(date -d 'today - 3 days' +%F)"
  cat > "$file" <<JSON
{
  "range": "7d",
  "totals": {"request_count": 300, "usage_usd": 12.34, "input_tokens": 900, "cached_input_tokens": 500, "output_tokens": 100},
  "buckets": [
    {"from": "${d1}T00:00:00Z", "request_count": 100, "usage_usd": 4.0, "input_tokens": 500, "cached_input_tokens": 400, "output_tokens": 0},
    {"from": "${d2}T00:00:00Z", "request_count": 200, "usage_usd": 8.34, "input_tokens": 400, "cached_input_tokens": 100, "output_tokens": 100},
    {"from": "2020-01-01T00:00:00Z", "request_count": 999, "usage_usd": 99.0, "input_tokens": 9999, "cached_input_tokens": 0, "output_tokens": 9999}
  ]
}
JSON
}

payload="$(make_fixture_dir)/usage.json"
make_payload "$payload"

# --- missing key: no cache, endpoint never consulted ------------------------
remove_key
out="$(run_collector "$payload" 200 --force)"
assert_eq "false" "$(jq -r .ready <<<"$out")" "no key: ready false"
assert_eq "ollama" "$(jq -r .id <<<"$out")" "no key: id"
assert_eq "[]" "$(jq -c .limits <<<"$out")" "no key: empty limits"
assert_contains "$out" "OLLAMA_API_KEY" "no key: auth help names the variable"

# --- happy path: record from the metered shape ------------------------------
write_key
out="$(run_collector "$payload" 200 --force)"
assert_eq "true" "$(jq -r .ready <<<"$out")" "ready true"
assert_eq "account" "$(jq -r .scope <<<"$out")" "scope account"
assert_eq "false" "$(jq -r .hasPromptStats <<<"$out")" "hasPromptStats false"
assert_eq "7" "$(jq -r '.recentDays | length' <<<"$out")" "seven chart days"
assert_eq "1000" "$(jq -r '[.recentDays[].messageCount] | add' <<<"$out")" "window tokens summed (out-of-window bucket ignored)"
assert_eq "2" "$(jq -r .activeDays <<<"$out")" "active days"
assert_eq "$(date +%F)" "$(jq -r '.recentDays[-1].date' <<<"$out")" "last chart row is today"
assert_eq '$12.34 · 300 requests (7d)' "$(jq -r .usageStatusText <<<"$out")" "dollar line"
assert_eq "0" "$(jq -r '.limits | length' <<<"$out")" "no percent limits"
assert_contains "$(cat "$(cache_file)")" '"id":"ollama"' "cache written on full run"

# --- failure with a warm cache: last good record re-emitted -----------------
out="$(run_collector "$payload" 500)"
assert_eq "true" "$(jq -r .ready <<<"$out")" "fetch failure: cached record"
assert_contains "$(jq -r .usageStatusText <<<"$out")" '$12.34' "fetch failure: cached dollar line"

# --- failure with a cold cache: unavailable record --------------------------
cold_cache="$(make_fixture_dir)"
out="$(env -i PATH="$FIXTURE_BIN:$PATH" HOME="$FIXTURE_HOME" XDG_CACHE_HOME="$cold_cache" \
  FAKE_CURL_PAYLOAD="$payload" FAKE_CURL_STATUS=500 bash "$SCRIPT" --force)"
assert_eq "false" "$(jq -r .ready <<<"$out")" "cold failure: ready false"
assert_eq "[]" "$(jq -c .limits <<<"$out")" "cold failure: empty limits"

# --- --limits-only must not touch the cache ---------------------------------
cold_cache="$(make_fixture_dir)"
out="$(env -i PATH="$FIXTURE_BIN:$PATH" HOME="$FIXTURE_HOME" XDG_CACHE_HOME="$cold_cache" \
  FAKE_CURL_PAYLOAD="$payload" FAKE_CURL_STATUS=200 bash "$SCRIPT" --limits-only)"
assert_eq "true" "$(jq -r .ready <<<"$out")" "limits-only: fresh record on stdout"
[[ -e "$cold_cache/omarchy/agent-usage/ollama.json" ]] && fail "limits-only wrote a cache file" || :
