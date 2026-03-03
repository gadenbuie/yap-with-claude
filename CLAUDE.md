# yap

> Maintain this file: keep it minimal, prune anything obvious from a repo scan, and update it when decisions change.

## Non-obvious decisions

- `--no-wait` forks before TTS; the child acquires `~/.cache/kokoro-onnx/yap.lock` immediately after `setsid()` to serialize playback across concurrent invocations while preserving invocation order
- `${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap` — resolves to bundled `yap` when installed as a plugin, falls back to PATH for local dev
- Per-workspace yap state: `.claude/yap-enabled` flag file, path derived from `cwd` in hook stdin JSON
- `#yap` toggle: `UserPromptSubmit` hook intercepts before Claude sees it, returns `decision: "block"` with `additionalContext`
- Marketplace: `gadenbuie/yap-with-claude` → install as `yap@yap-with-claude`
