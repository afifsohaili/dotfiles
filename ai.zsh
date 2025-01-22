function gcauto() {
  # Parse command line options
  local detailed=false
  local context_ref=""
  
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
      *)
        echo "Unknown option: $1"
        echo "Usage: gcauto [-d|--detailed] [-c|--context <git-ref>]"
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
    prompt="$prompt, generate a detailed commit message with a summary line (max 90 chars) followed by a blank line and then a detailed description of the changes."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output\\n\\nPROVIDE ONLY THE COMMIT MESSAGE AS IS, NO INTRODUCTORY TEXT."
  else
    prompt="Based on the following git diff"
    [ -n "$context" ] && prompt="$prompt and historical context"
    prompt="$prompt, generate a one-line commit message summarizing the changes (max 90 characters)."
    [ -n "$context" ] && prompt="$prompt\\n\\nContext:\\n$context"
    prompt="$prompt\\n\\nCurrent changes:\\n$diff_output\\n\\nPROVIDE ONLY THE ONE LINE GIT COMMIT MESSAGE AS IS, NEVER INCLUDE ANY IRRELEVANT THINGS."
  fi

  local ai_response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
        \"model\": \"claude-3-5-sonnet-20240620\",
        \"max_tokens\": 1024,
        \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"$prompt\"
        }
        ]
      }")

  # Use Ruby to parse the response and extract the commit message
  local commit_message=$(ruby -r json -e '
  begin
  response = JSON.parse(ARGV[0])
  if response["type"] == "error"
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
' "$ai_response")

  # Check if commit_message extraction was successful
  if [ $? -ne 0 ]; then
    echo "$commit_message"  # This will print the error message from Ruby
    return 1
  fi

  if [ -z "$commit_message" ]; then
    echo "Failed to generate commit message. API response:"
    echo "$ai_response"
    return 1
  fi

  # 3. Write the commit message
  echo "$commit_message" | git commit -F -

  echo "Commit created successfully with AI-generated message."
}

function cursor {
  $HOME/Applications/Cursor.app/Contents/MacOS/Cursor $@
}
