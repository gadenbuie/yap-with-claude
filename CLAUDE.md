# yap

A small single-file CLI that turns text into speech using [Kokoro TTS](https://github.com/thewh1teagle/kokoro-onnx) locally. No server, no Docker, no API keys.

## Quick orientation

- **`yap`** — Single-file Python CLI (PEP 723 inline script metadata). Executable directly; run with `uv run yap` or just `yap` if on `$PATH`.
- **`hooks/`** — Claude Code hook scripts (plugin root). `.claude/hooks/` contains symlinks to these.
- **`.claude-plugin/plugin.json`** — Plugin manifest.
- **`.claude-plugin/marketplace.json`** — Marketplace catalog; users install via `/plugin marketplace add gadenbuie/yap-with-claude` then `/plugin install yap@gadenbuie-yap`.
- **`_dev/`** — Research docs, planning notes. Not shipped.
- Model files (~300MB) auto-download to `~/.cache/kokoro-onnx/` on first run.

## Usage

```bash
yap "Hello world"              # speak text
echo "Hello" | yap             # pipe from stdin
yap -v am_fenrir "Hello"       # pick a voice
yap --voices                   # list voices
yap -o out.wav "Hello"         # save to file
yap -s 1.3 "Faster speech"    # adjust speed
yap --no-wait "Hello"          # fire-and-forget (returns immediately)
```

## Key decisions

- `kokoro-onnx` over `kokoro` (PyTorch) — ~60MB runtime vs ~2GB, simpler API
- PEP 723 inline script deps — no pyproject.toml, `uv run` just works
- `afplay` on macOS, `ffplay` fallback on Linux for playback
- Default voice: `am_fenrir` — override with `YAP_VOICE` env var
- Default speed: `1.25` — override with `YAP_SPEED` env var
- `--no-wait`: forks immediately after arg parsing, parent exits (releases Claude Code's process group), child calls `os.setsid()` and redirects fd 0/1/2 to `/dev/null` before doing TTS + playback

## Claude Code plugin

Distributed as a Claude Code plugin. Three hooks:

- **`hooks/yap-on-stop.sh`** — `Stop` event: strips markdown via `pandoc`, speaks Claude's last response
- **`hooks/yap-on-question.sh`** — `PreToolUse` (AskUserQuestion): reads all questions aloud with ordinal prefixes before the dialog appears
- **`hooks/yap-toggle.sh`** — `UserPromptSubmit`: intercepts `#yap` / `#yap on` / `#yap off`, toggles per-workspace flag file

Per-workspace state: `.claude/yap-enabled` (flag file derived from `cwd` in hook stdin JSON — works for both local and global installs).

Hooks call `yap --no-wait` with `</dev/null >/dev/null 2>&1 &` and `disown` to fully detach from Claude Code's process group and pipe FDs.

Hooks use `${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/}yap` — resolves to plugin-bundled `yap` when installed as a plugin, falls back to `yap` in PATH for local dev.

## #yap toggle

Users type `#yap`, `#yap on`, or `#yap off` in the Claude Code chat. The `UserPromptSubmit` hook intercepts it (before Claude sees it), updates the flag file, and returns `decision: "block"` with `additionalContext` informing Claude of the new state.
