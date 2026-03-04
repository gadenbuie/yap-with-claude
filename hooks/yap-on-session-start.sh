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
CONTEXT="The user has enabled yap text-to-speech. Your responses will be read aloud via a local TTS system. Keep this in mind. Always end sentences and list items with punctuation (period, comma, etc.) so the TTS reader pauses correctly between them — dangling phrases without terminal punctuation run together when spoken. You can also speak something aloud mid-conversation, before your final response, by calling the Bash tool with: yap \"your message here\". Use this to surface urgent findings, warnings, or important information while you are still working. The call is intercepted by a hook to run non-blocking; if the hook is not installed, yap will run directly."

jq -n --arg context "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $context
  }
}'
