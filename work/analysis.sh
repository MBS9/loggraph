#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
NAMES_FILE="$SCRIPT_DIR/names.json"
PROMPT_FILE="$SCRIPT_DIR/cluster_prompt.md"
OUTPUT_FILE="$SCRIPT_DIR/output.json"

jq -n --rawfile system_prompt "$PROMPT_FILE" --rawfile names "$NAMES_FILE" '{
  model: "deepseek-flash",
  messages: [
    {role: "system", content: $system_prompt},
    {role: "user", content: $names}
  ],
  thinking: {type: "enabled"},
  reasoning_effort: "medium",
  stream: false
}' | curl https://api.deepseek.com/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DEEPSEEK_API_KEY}" \
  -d @- >> "$OUTPUT_FILE"
