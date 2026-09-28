#!/bin/bash

# Grammar correction script using Fireworks AI API (kimi-k2p6)
# Make sure to set your FIREWORKS_API_KEY environment variable

grammar() {
    # check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found. Please install it."
        return 1
    fi

    # check if $FIREWORKS_API_KEY is set
    if [[ -z "$FIREWORKS_API_KEY" ]]; then
        echo "Error: FIREWORKS_API_KEY environment variable is not set."
        echo "Please set it with: export FIREWORKS_API_KEY='your-api-key'"
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

    echo "Sending request to Fireworks AI..."

    json_payload=$(jq -n \
                  --arg content "$input_text" \
                  '{
                    "model": "fireworks/kimi-k2p6",
                    "max_tokens": 1024,
                    "temperature": 0.6,
                    "messages": [
                      {
                        "role": "system",
                        "content": "You are an expert English professional communication advisor. Given these sentences, revise the tone and correct the grammar, with minimal change to the meaning. Output ONLY the corrected text. Do not include any reasoning, thinking, analysis, explanations, or summaries."
                      },
                      {
                        "role": "user",
                        "content": $content
                      }
                    ]
                  }')

    local tmp_resp=$(mktemp /tmp/grammar.XXXXXX)
    curl -s -w "\n%{http_code}" -X POST "https://api.fireworks.ai/inference/v1/chat/completions" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $FIREWORKS_API_KEY" \
        -d "$json_payload" > "$tmp_resp"

    local http_status=$(tail -n 1 "$tmp_resp")
    local body_file=$(mktemp /tmp/grammar_body.XXXXXX)
    sed '$d' "$tmp_resp" > "$body_file"
    rm -f "$tmp_resp"

    if [[ ! "$http_status" =~ ^2 ]]; then
        echo "API request failed with HTTP status $http_status. Response:"
        cat "$body_file"
        rm -f "$body_file"
        return 1
    fi

    corrected_text=$(ruby -r json -e '
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

    if [ $? -ne 0 ] || [[ -z "$corrected_text" ]]; then
        echo "Error: Failed to parse a valid response from Fireworks API."
        return 1
    fi

    echo ""
    echo "Here's your corrected sentence:\n\n"
    echo "$corrected_text"
}
