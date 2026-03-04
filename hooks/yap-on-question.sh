#!/usr/bin/env bash
# Hook: read pre-question preamble and AskUserQuestion questions aloud via yap
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

# Multiple hooks may fire for the same AskUserQuestion — deduplicate with an
# atomic mkdir marker keyed on tool_use_id
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // empty')
MARKER="/tmp/yap-asked-${TOOL_USE_ID}"
if ! mkdir "$MARKER" 2>/dev/null; then
  exit 0
fi

# Extract any preamble text Claude output before this tool call by scanning
# the tail of the transcript for text blocks from the current assistant turn.
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
PREAMBLE=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  RAW_PREAMBLE=$(python3 - "$TRANSCRIPT" <<'PYEOF'
import sys, json
transcript_path = sys.argv[1]

entries = []
for line in open(transcript_path):
    try:
        entries.append(json.loads(line))
    except Exception:
        pass

# Scan backwards: collect consecutive text blocks at the tail of the current
# assistant turn. Stop at any tool_use block or user message.
text_parts = []
for entry in reversed(entries):
    if entry.get('type') == 'user':
        break
    if entry.get('type') != 'assistant':
        continue
    content = entry.get('message', {}).get('content', [])
    if not content:
        continue
    block = content[0]
    if block.get('type') == 'text':
        text_parts.insert(0, block['text'].strip())
    else:
        break  # tool_use, thinking, or other — stop collecting

print(' '.join(t for t in text_parts if t))
PYEOF
  )
  if [ -n "$RAW_PREAMBLE" ]; then
    PREAMBLE=$(echo "$RAW_PREAMBLE" \
      | pandoc -f markdown -t plain --wrap=none \
      | tr '\n' ' ' \
      | sed -E 's/  +/ /g')
  fi
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

if [ -n "$PREAMBLE" ]; then
  TEXT="$PREAMBLE $TEXT"
fi

"${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap" --no-wait "$TEXT" </dev/null >/dev/null 2>&1 &
disown

exit 0
