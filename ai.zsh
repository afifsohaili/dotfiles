function gcauto() {
  # Parse command line options
  local detailed=false
  if [[ "$1" == "-d" ]] || [[ "$1" == "--detailed" ]]; then
    detailed=true
    shift  # Remove the flag from arguments
  fi

  # 1. Read the git diff of changes
  local diff_output=$(git diff --cached)

  if [ -z "$diff_output" ]; then
    echo "No staged changes found. Please stage your changes before running gcauto."
    return 1
  fi

    # Escape special characters and newlines in the diff output using Ruby
    diff_output=$(ruby -e "require 'json'; puts JSON.generate(ARGV[0].gsub(\"\n\", '\\n'))" "$diff_output")

    # Remove the surrounding quotes added by JSON.generate
    diff_output="${diff_output:1:-1}"

    # 2. Call Claude AI API with different prompts based on detailed flag
    local prompt
    if [ "$detailed" = true ]; then
      prompt="Based on the following git diff, generate a detailed commit message with a summary line (max 90 chars) followed by a blank line and then a detailed description of the changes:\\n\\n${diff_output}\\n\\nPROVIDE ONLY THE COMMIT MESSAGE AS IS, NO INTRODUCTORY TEXT."
    else
      prompt="Based on the following git diff, generate a one-line commit message summarizing the changes (max 90 characters):\\n\\n${diff_output}\\n\\nPROVIDE ONLY THE ONE LINE GIT COMMIT MESSAGE AS IS, NEVER INCLUDE ANY IRRELEVANT THINGS LIKE 'Here is your commit message' introductory paragraph."
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

