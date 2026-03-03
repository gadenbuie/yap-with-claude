# yap

Speaks Claude's responses aloud using [Kokoro TTS](https://github.com/thewh1teagle/kokoro-onnx) — locally, with no server, no Docker, and no API keys.

## Motivation

Working with Claude Code is often heads-down, eyes-on-screen work. Yap lets you step back — look away from the monitor, think, sketch on paper — while Claude keeps talking. It's also useful for accessibility, keeping up with long responses, or just making the experience feel more conversational.

Kokoro is a compact (~60MB), high-quality open-source TTS model that runs entirely on your machine via ONNX. Model files (~300MB) download automatically on first use.

Pair with a speach-to-text utility like [Spokenly](https://spokenly.app/) or [Wispr Flow](https://wisprflow.ai/) for back-and-forth conversations with Claude.

## Features

- **Reads responses aloud** — Claude's final message is spoken when it finishes
- **Reads questions aloud** — when Claude asks you something via `AskUserQuestion`, the question is spoken before the dialog appears
- **Per-workspace toggle** — type `#yap`, `#yap on`, or `#yap off` to control TTS without leaving your chat
- **Markdown-aware** — uses `pandoc` to convert Claude's markdown to clean plain text before speaking
- **Non-blocking** — speech plays in the background; Claude Code is never held up waiting for audio to finish
- **Local & private** — everything runs on your machine; no audio leaves your computer

## Requirements

- [uv](https://docs.astral.sh/uv/) — for running `yap`
- [pandoc](https://pandoc.org) — for markdown-to-plain-text conversion
- macOS (uses `afplay`) or Linux with `ffplay` installed

## Installation

### 1. Add the marketplace and install the plugin

From within a Claude Code session, add the yap marketplace and install the plugin:

```
/plugin marketplace add gadenbuie/yap-with-claude
/plugin install yap@yap-with-claude
```

This installs the plugin to your user scope (available across all projects) and registers all three hooks. The `yap` script is bundled inside the plugin — no separate download needed.

You can also install via the interactive UI: run `/plugin`, go to **Discover**, and select **yap**.

Model files (~300MB) download to `~/.cache/kokoro-onnx/` automatically on first use.

### 2. Enable yap

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
yap -v am_santa "Hello"              # pick a voice
yap --voices                         # list available voices
yap -o out.wav "Hello"               # save to file
yap -s 1.3 "Faster speech"           # adjust speed
yap --no-wait "Hello"                # fire-and-forget, returns immediately
```

The default voice is `am_fenrir` and the default speed is `1.25`.

### Changing the default voice and speed

Set `YAP_VOICE` and `YAP_SPEED` in your shell profile (e.g. `~/.zshrc` or `~/.bashrc`):

```bash
export YAP_VOICE=af_heart
export YAP_SPEED=1.1
```

These apply to both the Claude Code hooks and direct CLI usage. Run `yap --voices` to see all available voices.

## How it works

Three Claude Code hooks wire everything together:

| Hook | Event | What it does |
|---|---|---|
| `yap-on-stop.sh` | `Stop` | Strips markdown from Claude's last message via `pandoc`, speaks it |
| `yap-on-question.sh` | `PreToolUse` (AskUserQuestion) | Reads all questions aloud before the dialog appears |
| `yap-toggle.sh` | `UserPromptSubmit` | Intercepts `#yap` commands, updates the per-workspace flag file |

The per-workspace state is stored in `.claude/yap-enabled` (a flag file — present means on, absent means off). This path is derived from the `cwd` field in each hook's stdin JSON, so the hooks work correctly whether installed locally or globally.
