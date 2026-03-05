#!/usr/bin/env bash
# Hook: intercept /yap commands to toggle TTS on/off
set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Only handle /yap commands
case "$PROMPT" in
  "#yap on"*)  ACTION="on"  ;;
  "#yap off"*) ACTION="off" ;;
  "#yap"*)     ACTION="toggle" ;;
  *)           exit 0 ;;
esac

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FLAG_FILE="$CWD/.claude/yap-enabled"

if [ "$ACTION" = "on" ]; then
  touch "$FLAG_FILE"
  STATE="on"
elif [ "$ACTION" = "off" ]; then
  rm -f "$FLAG_FILE"
  STATE="off"
else
  # Toggle
  if [ -f "$FLAG_FILE" ]; then
    rm -f "$FLAG_FILE"
    STATE="off"
  else
    touch "$FLAG_FILE"
    STATE="on"
  fi
fi

if [ "$STATE" = "on" ]; then
  REASON="Yap is now ON — responses will be read aloud."
  # Keep in sync with yap-on-session-start.sh (on-state CONTEXT)
  CONTEXT="The user has enabled yap text-to-speech. Your responses will be read aloud via a local TTS system. Keep this in mind. Always end sentences and list items with punctuation (period, comma, etc.) so the TTS reader pauses correctly between them — dangling phrases without terminal punctuation run together when spoken. IMPORTANT: any text you write before a tool call is NOT spoken — it is silently dropped. If you want the user to hear something before or while you work, you MUST call the Bash tool first: yap \"your message here\". The call is intercepted and runs non-blocking, so it does not slow you down. Use this whenever you would otherwise narrate what you are about to do or share an intermediate finding. When the hook intercepts the call, it will return a block decision — this is the success state, not an error. Continue with your task normally after calling yap."
else
  REASON="Yap is now OFF — responses will not be read aloud."
  CONTEXT="The user has disabled yap text-to-speech. Your responses will no longer be read aloud."
fi

jq -n \
  --arg reason "$REASON" \
  --arg context "$CONTEXT" \
  '{
    decision: "block",
    reason: $reason,
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $context
    }
  }'
