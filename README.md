# yap

Speaks Claude's responses aloud using [Kokoro TTS](https://github.com/thewh1teagle/kokoro-onnx) — locally, with no server, no Docker, and no API keys.

## Motivation

Working with Claude Code is often heads-down, eyes-on-screen work. Yap lets you step back — look away from the monitor, think, sketch on paper — while Claude keeps talking. It's also useful for accessibility, keeping up with long responses, or just making the experience feel more conversational.

Kokoro is a compact (~60MB), high-quality open-source TTS model that runs entirely on your machine via ONNX. Model files (~300MB) download automatically on first use.

## Features

- **Reads responses aloud** — Claude's final message is spoken when it finishes
- **Reads questions aloud** — when Claude asks you something via `AskUserQuestion`, the question is spoken before the dialog appears
- **Per-workspace toggle** — type `#yap`, `#yap on`, or `#yap off` to control TTS without leaving your chat
- **Markdown-aware** — uses `pandoc` to convert Claude's markdown to clean plain text before speaking
- **Non-blocking** — speech plays in the background; Claude Code is never held up waiting for audio to finish
- **Local & private** — everything runs on your machine; no audio leaves your computer

## Requirements

- [uv](https://docs.astral.sh/uv/) — for running the `yap` script
- [pandoc](https://pandoc.org) — for markdown-to-plain-text conversion
- macOS (uses `afplay`) or Linux with `ffplay` installed

## Installation

### 1. Install `yap`

Put `yap` somewhere on your `$PATH`:

```bash
# Option A: clone and symlink
git clone https://github.com/gadenbuie/yap
ln -s "$PWD/yap/yap" /usr/local/bin/yap

# Option B: download directly
curl -o /usr/local/bin/yap https://raw.githubusercontent.com/gadenbuie/yap/main/yap
chmod +x /usr/local/bin/yap
```

Verify it works:

```bash
yap "Hello, world"
```

Model files will download to `~/.cache/kokoro-onnx/` on first run (~300MB, one-time).

### 2. Install as a Claude Code plugin

```bash
claude plugin install gadenbuie/yap --scope user
```

This registers the hooks globally, so yap is available in every Claude Code session.

### 3. Enable yap

By default, yap is **off** — it only speaks when you turn it on. In any Claude Code session:

```
#yap
```

to toggle it on. Your preference is saved per workspace in `.claude/yap-enabled`.

## Usage

| Command | Effect |
|---|---|
| `#yap` | Toggle TTS on/off |
| `#yap on` | Enable TTS |
| `#yap off` | Disable TTS |

Or use `yap` directly from the terminal:

```bash
yap "Hello world"                    # speak text
echo "Hello" | yap                   # pipe from stdin
yap -v am_fenrir "Hello"             # pick a voice
yap --voices                         # list available voices
yap -o out.wav "Hello"               # save to file
yap -s 1.3 "Faster speech"          # adjust speed
```

The default voice is `af_heart` (highest-rated). The hooks use `am_fenrir`.

## How it works

Three Claude Code hooks wire everything together:

| Hook | Event | What it does |
|---|---|---|
| `yap-on-stop.sh` | `Stop` | Strips markdown from Claude's last message via `pandoc`, speaks it |
| `yap-on-question.sh` | `PreToolUse` (AskUserQuestion) | Reads all questions aloud before the dialog appears |
| `yap-toggle.sh` | `UserPromptSubmit` | Intercepts `#yap` commands, updates the per-workspace flag file |

The per-workspace state is stored in `.claude/yap-enabled` (a flag file — present means on, absent means off). This path is derived from the `cwd` field in each hook's stdin JSON, so the hooks work correctly whether installed locally or globally.
