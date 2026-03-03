#!/usr/bin/env bash
# Hook: intercept `yap "..."` Bash calls — adds --no-wait and respects the flag file
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only handle `yap "..."` calls — pass through everything else
case "$COMMAND" in
  yap\ *) ;;
  *) exit 0 ;;
esac

# Extract the message from: yap "msg" or yap 'msg'
MESSAGE=$(echo "$COMMAND" | sed -E "s/^yap [\"'](.+)[\"']$/\1/")

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FLAG_FILE="$CWD/.claude/yap-enabled"

if [ -f "$FLAG_FILE" ] && [ -n "$MESSAGE" ]; then
  "${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap" --no-wait "$MESSAGE" </dev/null >/dev/null 2>&1 &
  disown
fi

# Block the synchronous yap call — we already fired it with --no-wait above
jq -n '{decision: "block", reason: "yap intercepted by yap-on-yap hook"}'
