#!/usr/bin/env bash
# Hook: inject yap context at session start when yap is already enabled
set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FLAG_FILE="$CWD/.claude/yap-enabled"

if [ ! -f "$FLAG_FILE" ]; then
  exit 0
fi

# Keep in sync with yap-toggle.sh (on-state CONTEXT)
CONTEXT="The user has enabled yap text-to-speech. Your responses will be read aloud via a local TTS system. Keep this in mind. Always end sentences and list items with punctuation (period, comma, etc.) so the TTS reader pauses correctly between them — dangling phrases without terminal punctuation run together when spoken. IMPORTANT: any text you write before a tool call is NOT spoken — it is silently dropped. If you want the user to hear something before or while you work, you MUST call the Bash tool first: yap \"your message here\". The call is intercepted and runs non-blocking, so it does not slow you down. Use this whenever you would otherwise narrate what you are about to do or share an intermediate finding. When the hook intercepts the call, it will return a block decision — this is the success state, not an error. Continue with your task normally after calling yap."

jq -n --arg context "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $context
  }
}'
