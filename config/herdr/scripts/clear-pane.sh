#!/bin/bash
# herdr prefix+k — tmux-style clear pane
#
# Mirrors tmux:  bind k send-keys -R \; clear-history
#   * at a shell prompt: wipe scrollback (ESC[3J), clear screen (ESC[2J), home cursor (ESC[H)
#   * agent pane / non-shell foreground app: nothing happens, a toast explains why
#
# Run via [[keys.command]] type="shell", so herdr provides:
#   HERDR_ACTIVE_PANE_ID, HERDR_BIN_PATH, HERDR_SOCKET_PATH, HERDR_ACTIVE_PANE_CWD
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
PANE_ID="${HERDR_ACTIVE_PANE_ID:-}"

if [[ -z "$PANE_ID" ]]; then
  exit 1
fi

notify() {
  "$HERDR" notification show "$1" --body "$2" --position bottom-right >/dev/null 2>&1 || true
}

# 1. Agent pane? Agent TUIs run in the alternate screen — herdr keeps no scrollback
#    for them, and we must not type into the agent. Toast and stop.
if "$HERDR" agent list 2>/dev/null | grep -q "\"pane_id\":\"${PANE_ID}\""; then
  notify "Pane not cleared" "Agent is running in this pane."
  exit 0
fi

# 2. Foreground process must be an interactive shell (i.e. pane is at a prompt).
FG_NAME="$("$HERDR" pane process-info --pane "$PANE_ID" 2>/dev/null \
  | grep -o '"name":"[^"]*"' | head -n1 | cut -d'"' -f4)"

case "$FG_NAME" in
  zsh|bash|sh|dash|ksh|fish|nu|tcsh|csh)
    # Cancel anything already typed on the input line (else pane run would
    # append to it, e.g. "asd" + printf -> "asdprintf"). The ^C artifact is
    # wiped by the clear that follows.
    "$HERDR" pane send-keys "$PANE_ID" ctrl+c
    # ESC[3J = clear scrollback history, ESC[2J = clear screen, ESC[H = home cursor
    "$HERDR" pane run "$PANE_ID" 'printf "\033[3J\033[2J\033[H"'
    ;;
  *)
    notify "Pane not cleared" "Foreground is ${FG_NAME:-unknown} — clear from a shell prompt."
    ;;
esac
