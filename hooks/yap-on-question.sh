#!/usr/bin/env bash
# Hook: read all AskUserQuestion questions aloud via yap
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FLAG_FILE="$CWD/.claude/yap-enabled"

# Only run if yap is enabled
if [ ! -f "$FLAG_FILE" ]; then
  exit 0
fi

COUNT=$(echo "$INPUT" | jq '.tool_input.questions | length')
if [ "$COUNT" -eq 0 ]; then
  exit 0
fi

ORDINALS=("1st" "2nd" "3rd")

if [ "$COUNT" -eq 1 ]; then
  QUESTION=$(echo "$INPUT" | jq -r '.tool_input.questions[0].question')
  TEXT="I have a question for you. $QUESTION"
else
  TEXT="I have a question for you."
  for i in $(seq 0 $((COUNT - 1))); do
    QUESTION=$(echo "$INPUT" | jq -r ".tool_input.questions[$i].question")
    if [ "$i" -lt 3 ]; then
      ORDINAL="${ORDINALS[$i]}"
    else
      ORDINAL="$((i + 1))th"
    fi
    TEXT="$TEXT $ORDINAL question. $QUESTION"
  done
fi

"${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap" --no-wait "$TEXT" </dev/null >/dev/null 2>&1 &
disown

exit 0
