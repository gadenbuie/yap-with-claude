#!/usr/bin/env bash
# Hook: read Claude's final response aloud via yap
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FLAG_FILE="$CWD/.claude/yap-enabled"

# Only run if yap is enabled
if [ ! -f "$FLAG_FILE" ]; then
  exit 0
fi

# Prevent infinite loops — skip if we're already in a stop hook continuation
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Extract Claude's response text
MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
if [ -z "$MESSAGE" ]; then
  exit 0
fi

# Strip markdown formatting for cleaner speech
CLEAN=$(echo "$MESSAGE" \
  | pandoc -f markdown -t plain --wrap=none \
  | tr '\n' ' ' \
  | sed -E 's/  +/ /g' \
  | head -c 2000)

if [ -z "$CLEAN" ]; then
  exit 0
fi

yap -v am_fenrir "$CLEAN" &
disown
exit 0
