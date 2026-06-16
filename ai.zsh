function gcauto() {
  local vendor="crof"
  local forwarded_args=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --claude)
        vendor="claude"
        shift
        ;;
      --crof)
        vendor="crof"
        shift
        ;;
      *)
        forwarded_args+=("$1")
        shift
        ;;
    esac
  done

  if [ "$vendor" = "claude" ]; then
    gcauto_claude "${forwarded_args[@]}"
  else
    gcauto_crof "${forwarded_args[@]}"
  fi
}

function gcauto_claude() {
  # Parse command line options
  local detailed=false
  local context_ref=""
  local additional_instructions=""
  local model="claude-sonnet-4-5"

  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--detailed)
        detailed=true
        shift
        ;;
      -c|--context)
        if [[ -z "$2" ]]; then
          echo "Error: --context requires a git reference argument"
          return 1
        fi
        context_ref="$2"
        shift 2
        ;;
      -a|--additional-instructions)
        if [[ -z "$2" ]]; then
          echo "Error: --additional-instructions requires a string argument"
          return 1
        fi
        additional_instructions="$2"
        shift 2
        ;;
      --model)
        if [[ -z "$2" ]]; then
          echo "Error: --model requires a model id argument"
          return 1
        fi
        model="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: gcauto_claude [-d|--detailed] [-c|--context <git-ref>] [-a|--additional-instructions <text>] [--model <model-id>]"
        return 1
        ;;
    esac
  done

  # 1. Read the git diff of changes
  local diff_output=$(git diff --cached)

  if [ -z "$diff_output" ]; then
    echo "No staged changes found. Please stage your changes before running gcauto."
    return 1
  fi

  # Get context from previous commits if context_ref is provided
  local context=""
  if [ -n "$context_ref" ]; then
    # Get the list of commits between context_ref and HEAD
    local commits=$(git log --reverse --pretty=format:"%H" $context_ref..HEAD)

    if [ -n "$commits" ]; then
      # Create context using a more robust JSON escaping approach
      context=$(ruby -e '
        require "json"
        commits = ARGV[0].split("\n")
        context = "Here is the context of recent changes:\n"
        commits.each do |commit|
          commit_message = `git log -1 --pretty=format:"%s%n%n%b" #{commit}`
          commit_diff = `git show --pretty=format:"" #{commit}`
          context += "Commit: #{commit_message}\n"
          context += "Changes:\n#{commit_diff}\n\n"
        end
        puts JSON.generate(context)
      ' "$commits")
      # Remove the surrounding quotes from the JSON-encoded string
      context="${context:1:-1}"
    fi
  fi

  # Similarly, use Ruby to escape the diff output more robustly
  diff_output=$(ruby -e '
    require "json"
    diff = `git diff --cached`
    puts JSON.generate(diff)
  ')
  # Remove the surrounding quotes from the JSON-encoded string
  diff_output="${diff_output:1:-1}"

  # 2. Call Claude AI API with different prompts based on flags
  local prompt
  if [ "$detailed" = true ]; then
    prompt="Based on the following git diff"
    [ -n "$context" ] && prompt="$prompt and historical context"
    prompt="$prompt, generate a detailed commit message with a summary line (max 72 chars) followed by a blank line and then a detailed description of the changes."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output"
    [ -n "$additional_instructions" ] && prompt="$prompt\\n\\nAdditional instructions:\\n$additional_instructions"
    prompt="$prompt\\n\\nPROVIDE ONLY THE COMMIT MESSAGE AS IS, NO INTRODUCTORY TEXT. Do NOT use 'feat:', 'fix:', 'chore:', or any other prefix. Be concise and to the point. You can sacrifice some details and grammar for brevity."
  else
    prompt="Based on the following git diff"
    [ -n "$context" ] && prompt="$prompt and historical context"
    prompt="$prompt, generate a one-line commit message summarizing the changes (max 72 characters)."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output"
    [ -n "$additional_instructions" ] && prompt="$prompt\\n\\nAdditional context:\\n$additional_instructions"
    prompt="$prompt\\n\\nPROVIDE ONLY THE ONE LINE GIT COMMIT MESSAGE AS IS, NEVER INCLUDE ANY IRRELEVANT THINGS. Do NOT use 'feat:', 'fix:', 'chore:', or any other prefix. Be concise and to the point. You can sacrifice some details and grammar for brevity."
  fi

  local ai_response=$(curl -s -w "\n%{http_code}" -X POST "https://api.anthropic.com/v1/messages" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
        \"model\": \"$model\",
        \"max_tokens\": 1024,
        \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"$prompt\"
        }
        ]
      }")

  local http_status=$(echo "$ai_response" | tail -n 1)
  local response_body=$(echo "$ai_response" | sed '$d')

  if [[ ! "$http_status" =~ ^2 ]]; then
    echo "API request failed with HTTP status $http_status. Response:"
    echo "$response_body"
    return 1
  fi

  # Use Ruby to parse the response and extract the commit message
  local commit_message=$(printf '%s\n' "$response_body" | ruby -r json -e '
begin
response = JSON.parse(STDIN.read)
if response["error"]
  puts "Error from API: #{response["error"]["message"]}"
  exit 1
end
puts response["content"][0]["text"]
rescue JSON::ParserError => e
puts "Failed to parse API response: #{e.message}"
exit 1
rescue => e
puts "Unexpected error: #{e.message}"
exit 1
end
')

  # Check if commit_message extraction was successful
  if [ $? -ne 0 ]; then
    echo "$commit_message"  # This will print the error message from Ruby
    return 1
  fi

  if [ -z "$commit_message" ]; then
    echo "Failed to generate commit message. API response:"
    echo "$response_body"
    return 1
  fi

  # 3. Write the commit message
  echo "$commit_message" | git commit -F -

  echo "Commit created successfully with $model."
}

function _gcauto_crof() {
  # Parse command line options
  local detailed=false
  local context_ref=""
  local additional_instructions=""
  local model="deepseek-v4-pro"

  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--detailed)
        detailed=true
        shift
        ;;
      -c|--context)
        if [[ -z "$2" ]]; then
          echo "Error: --context requires a git reference argument"
          return 1
        fi
        context_ref="$2"
        shift 2
        ;;
      -a|--additional-instructions)
        if [[ -z "$2" ]]; then
          echo "Error: --additional-instructions requires a string argument"
          return 1
        fi
        additional_instructions="$2"
        shift 2
        ;;
      --model)
        if [[ -z "$2" ]]; then
          echo "Error: --model requires a model id argument"
          return 1
        fi
        model="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: gcauto_crof [-d|--detailed] [-c|--context <git-ref>] [-a|--additional-instructions <text>] [--model <model-id>]"
        return 1
        ;;
    esac
  done

  # 1. Read the git diff of changes
  local diff_output=$(git diff --cached)

  if [ -z "$diff_output" ]; then
    echo "No staged changes found. Please stage your changes before running gcauto."
    return 1
  fi

  # Get context from previous commits if context_ref is provided
  local context=""
  if [ -n "$context_ref" ]; then
    local commits=$(git log --reverse --pretty=format:"%H" $context_ref..HEAD)

    if [ -n "$commits" ]; then
      context=$(ruby -e '
        require "json"
        commits = ARGV[0].split("\n")
        context = "Here is the context of recent changes:\n"
        commits.each do |commit|
          commit_message = `git log -1 --pretty=format:"%s%n%n%b" #{commit}`
          commit_diff = `git show --pretty=format:"" #{commit}`
          context += "Commit: #{commit_message}\n"
          context += "Changes:\n#{commit_diff}\n\n"
        end
        puts JSON.generate(context)
      ' "$commits")
      context="${context:1:-1}"
    fi
  fi

  diff_output=$(ruby -e '
    require "json"
    diff = `git diff --cached`
    puts JSON.generate(diff)
  ')
  diff_output="${diff_output:1:-1}"

  # 2. Build prompt
  local prompt
  if [ "$detailed" = true ]; then
    prompt="Based on the following git diff"
    [ -n "$context" ] && prompt="$prompt and historical context"
    prompt="$prompt, generate a detailed commit message with a summary line (max 72 chars) followed by a blank line and then a detailed description of the changes."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output"
    [ -n "$additional_instructions" ] && prompt="$prompt\\n\\nAdditional instructions:\\n$additional_instructions"
    prompt="$prompt\\n\\nPROVIDE ONLY THE COMMIT MESSAGE AS IS, NO INTRODUCTORY TEXT. Do NOT use 'feat:', 'fix:', 'chore:', or any other prefix. Be concise and to the point. You can sacrifice some details and grammar for brevity."
  else
    prompt="Based on the following git diff"
    [ -n "$context" ] && prompt="$prompt and historical context"
    prompt="$prompt, generate a one-line commit message summarizing the changes (max 72 characters)."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output"
    [ -n "$additional_instructions" ] && prompt="$prompt\\n\\nAdditional context:\\n$additional_instructions"
    prompt="$prompt\\n\\nPROVIDE ONLY THE ONE LINE GIT COMMIT MESSAGE AS IS, NEVER INCLUDE ANY IRRELEVANT THINGS. Do NOT use 'feat:', 'fix:', 'chore:', or any other prefix. Be concise and to the point. You can sacrifice some details and grammar for brevity."
  fi

  # 3. Call CrofAI API (OpenAI-compatible format)
  local tmp_resp=$(mktemp /tmp/gcauto_crof.XXXXXX)
  curl -s -w "\n%{http_code}" -X POST "https://crof.ai/v1/chat/completions" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CROF_API_KEY" \
    -d "{
        \"model\": \"$model\",
        \"max_tokens\": 4096,
        \"reasoning_effort\": \"none\",
        \"temperature\": 0.6,
        \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"$prompt\"
        }
        ]
      }" > "$tmp_resp"

  local http_status=$(tail -n 1 "$tmp_resp")
  local body_file=$(mktemp /tmp/gcauto_crof_body.XXXXXX)
  sed '$d' "$tmp_resp" > "$body_file"
  rm -f "$tmp_resp"

  if [[ ! "$http_status" =~ ^2 ]]; then
    echo "API request failed with HTTP status $http_status. Response:"
    cat "$body_file"
    rm -f "$body_file"
    return 1
  fi

  local commit_message=$(ruby -r json -e '
begin
response = JSON.parse(File.read(ARGV[0]))
if response["error"]
  puts "Error from API: #{response["error"]["message"]}"
  exit 1
end
puts response["choices"][0]["message"]["content"]
rescue JSON::ParserError => e
puts "Failed to parse API response: #{e.message}"
exit 1
rescue => e
puts "Unexpected error: #{e.message}"
exit 1
end
' "$body_file")

  rm -f "$body_file"

  if [ $? -ne 0 ]; then
    echo "$commit_message"
    return 1
  fi

  if [ -z "$commit_message" ]; then
    echo "Failed to generate commit message."
    return 1
  fi

  # 4. Write the commit message
  echo "$commit_message" | git commit -F -
  echo "Commit created successfully with crof.ai/$model."
}

function gcauto_crof() {
  _gcauto_crof "$@"
}

function makeplan() {
    if [ -z "$1" ]; then
        echo "Usage: makeplan <plan>"
        return 1
    fi
    # if there's no .git, raise an error
    if [ ! -d .git ]; then
        echo "Error: Not a git repository"
        return 1
    fi
    # if there's no plans directory, create it
    if [ ! -d plans ]; then
        mkdir -p plans
    fi
    mkdir -p plans/$1
    mkdir -p plans/$1/screens
    touch plans/$1/plan-$1.md

    # include in .gitignore
    echo "!plans/$1" >> .gitignore
}
