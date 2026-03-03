# yap

A small single-file CLI that turns text into speech using [Kokoro TTS](https://github.com/thewh1teagle/kokoro-onnx) locally. No server, no Docker, no API keys.

## Quick orientation

- **`yap.py`** — Single-file Python CLI (PEP 723 inline script metadata). Run with `uv run yap.py`.
- **`_dev/`** — Research docs, planning notes. Not shipped.
- Model files (~300MB) auto-download to `~/.cache/kokoro-onnx/` on first run.

## Usage

```bash
uv run yap.py "Hello world"              # speak text
echo "Hello" | uv run yap.py             # pipe from stdin
uv run yap.py -v am_fenrir "Hello"       # pick a voice
uv run yap.py --voices                   # list voices
uv run yap.py -o out.wav "Hello"         # save to file
uv run yap.py -s 1.3 "Faster speech"    # adjust speed
```

## Key decisions

- `kokoro-onnx` over `kokoro` (PyTorch) — ~60MB runtime vs ~2GB, simpler API
- PEP 723 inline script deps — no pyproject.toml, `uv run` just works
- `afplay` on macOS, `ffplay` fallback on Linux for playback
- Default voice: `af_heart` (highest rated)

## Claude Code hooks integration

- `.claude/hooks/yap-on-stop.sh` — Stop hook that reads Claude's response aloud
- `.claude/settings.local.json` — Enables the hook (local only, not committed)
- Uses `last_assistant_message` field from the Stop event stdin JSON
- Strips markdown (code blocks, tables, bold, links, etc.) before speaking
- Checks `stop_hook_active` to prevent infinite loops
- Runs `uv run yap.py` in the background so it doesn't block Claude
- Text is truncated to 2000 chars to keep speech reasonable

## Future directions

- Streaming playback for long text
- Possibly package as a proper `uv` project with `[project.scripts]` entrypoint
