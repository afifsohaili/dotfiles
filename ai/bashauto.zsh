function bashauto() {
  local type_flag=false
  local return_flag=false
  local copy_flag=false
  local forwarded_args=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      -t|--type)
        type_flag=true
        shift
        ;;
      -r|--return)
        return_flag=true
        shift
        ;;
      -c|--copy)
        copy_flag=true
        shift
        ;;
      -h|--help)
        echo "Usage: bashauto [-t|--type] [-r|--return] [-c|--copy] <description>"
        echo ""
        echo "Generate a bash command from a natural language description using opencode."
        echo ""
        echo "Options:"
        echo "  -t, --type     Paste the command at the current cursor via Cmd+V (macOS only)"
        echo "  -r, --return   Also press Return after typing (requires --type)"
        echo "  -c, --copy     Copy the command to clipboard"
        echo "  -h, --help     Show this help message"
        return 0
        ;;
      *)
        forwarded_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#forwarded_args[@]} -eq 0 ]]; then
    echo "Usage: bashauto [-t|--type] [-r|--return] [-c|--copy] <description>" >&2
    return 1
  fi

  local description="${forwarded_args[*]}"
  local cwd=$(pwd)

  local prompt="You are an expert shell command generator.

Your job: convert the user's task into a single, executable bash/zsh command.

Rules:
- Output ONLY the raw command.
- NO markdown code fences (no \`\`\`bash or \`\`\`).
- NO explanation, NO intro, NO outro.
- NO quotes around the entire command.
- The command must be safe and runnable in the current shell.
- Prefer modern, concise tools when available.
- If the task is ambiguous, produce the most likely interpretation.

Context:
- Current directory: $cwd
- The current shell is zsh. Prefer commands that work in zsh.
- Inspect the current directory and project files as needed to produce the correct command.

Task: $description

Command:"

  local tmpfile=$(mktemp /tmp/bashauto.XXXXXX)
  local stderr_file=$(mktemp /tmp/bashauto_err.XXXXXX)

  opencode run \
    --format json \
    --title "bashauto: $description" \
    "$prompt" > "$tmpfile" 2> "$stderr_file"

  local run_exit_code=$?

  local session_id=""
  if [[ -s "$tmpfile" ]]; then
    session_id=$(jq -r 'select(.sessionID != null) | .sessionID' "$tmpfile" 2>/dev/null | head -n 1)
  fi

  local generated_command=""
  if [[ -s "$tmpfile" ]]; then
    generated_command=$(jq -rs '[.[] | select(.type == "text") | .part.text] | add // empty' "$tmpfile" 2>/dev/null)
  fi

  # Clean up markdown fences and surrounding whitespace
  generated_command=$(echo "$generated_command" | sed \
    -e 's/^[[:space:]]*```bash//' \
    -e 's/^[[:space:]]*```sh//' \
    -e 's/^[[:space:]]*```//' \
    -e 's/```[[:space:]]*$//' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//')

  # Delete the ephemeral session
  if [[ -n "$session_id" ]]; then
    opencode session delete "$session_id" >/dev/null 2>&1 || true
  fi

  rm -f "$tmpfile" "$stderr_file"

  if [[ $run_exit_code -ne 0 || -z "$generated_command" ]]; then
    echo "Error: failed to generate command" >&2
    return 1
  fi

  if $copy_flag; then
    echo "$generated_command" | pbcopy
    echo "$generated_command"
    echo "(copied to clipboard)"
  elif $type_flag; then
    echo "$generated_command" | pbcopy
    echo "$generated_command"
    osascript -e 'tell application "System Events" to keystroke "v" using command down' >/dev/null 2>&1
    if $return_flag; then
      sleep 0.1
      osascript -e 'tell application "System Events" to key code 36' >/dev/null 2>&1
    fi
  else
    echo "$generated_command"
  fi
}
