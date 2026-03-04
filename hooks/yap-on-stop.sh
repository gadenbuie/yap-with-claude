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

# Skip if Claude stopped to ask a question — yap-on-question.sh handles that turn
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  LAST_TOOL=$(python3 -c "
import sys, json
entries = []
for line in open('$TRANSCRIPT'):
    try: entries.append(json.loads(line))
    except: pass
for entry in reversed(entries):
    if entry.get('type') == 'assistant':
        for block in entry.get('message', {}).get('content', []):
            if block.get('type') == 'tool_use':
                print(block.get('name', ''))
                sys.exit(0)
        break  # examined the most-recent assistant entry; stop scanning
" 2>/dev/null)
  if [ "$LAST_TOOL" = "AskUserQuestion" ]; then
    exit 0
  fi
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
  | sed -E 's/  +/ /g')

if [ -z "$CLEAN" ]; then
  exit 0
fi

# Truncate with a spoken notice if the message exceeds the limit
LIMIT=2000
if [ "${#CLEAN}" -gt "$LIMIT" ]; then
  CLEAN="${CLEAN:0:$LIMIT}... I'm stopping here, but there's more to my message in Claude Code."
fi

"${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap" --no-wait "$CLEAN" </dev/null >/dev/null 2>&1 &
disown
exit 0
