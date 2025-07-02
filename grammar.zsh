#!/bin/bash

# Grammar correction script using Claude API
# Make sure to set your ANTHROPIC_API_KEY environment variable

grammar() {
    # check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found. Please install it."
        return 1
    fi

    # check if $ANTHROPIC_API_KEY is set
    if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        echo "Error: ANTHROPIC_API_KEY environment variable is not set."
        echo "Please set it with: export ANTHROPIC_API_KEY='your-api-key'"
        return 1
    fi

    echo "Please input your text:"
    echo "(Press Ctrl+D when finished)"

    # Read multi-line input
    input_text=$(cat)

    if [[ -z "$input_text" ]]; then
        echo "No input provided."
        return 1
    fi

    echo "Sending request to Claude..."

    json_payload=$(jq -n \
                  --arg content "$input_text" \
                  '{
                    "model": "claude-3-5-sonnet-20240620",
                    "max_tokens": 1024,
                    "system": "You are an expert English professional communication advisor. Given these sentences, revise the tone and correct the grammar, with minimal change to the meaning. When replying, only directly give me the answer. No need to summarize the changes as well.",
                    "messages": [
                      {
                        "role": "user",
                        "content": $content
                      }
                    ]
                  }')

    response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$json_payload")

    # Use 'printf' to pipe the response to jq safely, preventing issues with newlines
    error_message=$(printf "%s" "$response" | jq -r '.error.message' 2>/dev/null)
    if [[ "$error_message" != "null" ]] && [[ -n "$error_message" ]]; then
        echo "Error: API returned an error."
        echo "Message: $error_message"
        return 1
    fi

    # Use 'printf' here as well for consistency and safety
    corrected_text=$(printf "%s" "$response" | jq -r '.content[0].text' 2>/dev/null)

    if [[ "$corrected_text" == "null" ]] || [[ -z "$corrected_text" ]]; then
        echo "Error: Failed to parse a valid response from Claude API."
        echo "Response: $response"
        return 1
    fi

    echo ""
    echo "Here's your corrected sentence:\n\n"
    echo "$corrected_text"
}
