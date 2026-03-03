#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "kokoro-onnx>=0.5.0",
#     "soundfile",
# ]
# ///
"""yap — turn text into speech using Kokoro TTS (local, no server needed)."""

import argparse
import fcntl
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.request import urlretrieve

import soundfile as sf
from kokoro_onnx import Kokoro

CACHE_DIR = Path.home() / ".cache" / "kokoro-onnx"
MODEL_URL = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx"
VOICES_URL = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin"

DEFAULT_VOICE = os.environ.get("YAP_VOICE", "am_fenrir")
DEFAULT_SPEED = float(os.environ.get("YAP_SPEED", "1.25"))


def ensure_model() -> tuple[Path, Path]:
    """Download model files on first run. Returns (model_path, voices_path)."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    model_path = CACHE_DIR / "kokoro-v1.0.onnx"
    voices_path = CACHE_DIR / "voices-v1.0.bin"

    for path, url in [(model_path, MODEL_URL), (voices_path, VOICES_URL)]:
        if not path.exists():
            print(f"Downloading {path.name}...", file=sys.stderr)
            urlretrieve(url, path)
            print(f"  saved to {path}", file=sys.stderr)

    return model_path, voices_path


LOCK_FILE = CACHE_DIR / "yap.lock"


def play(path: str) -> None:
    """Play a wav file using the system player."""
    if sys.platform == "darwin":
        subprocess.run(["afplay", path], check=True)
    else:
        subprocess.run(
            ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", path],
            check=True,
        )


def list_voices(kokoro: Kokoro) -> None:
    """Print available voices."""
    for v in sorted(kokoro.get_voices()):
        print(v)


def main() -> None:
    p = argparse.ArgumentParser(
        prog="yap",
        description="Turn text into speech using Kokoro TTS (runs locally).",
    )
    p.add_argument("text", nargs="*", help="Text to speak (or pipe via stdin)")
    p.add_argument("-v", "--voice", default=DEFAULT_VOICE, help=f"Voice ID (default: {DEFAULT_VOICE})")
    p.add_argument("-s", "--speed", type=float, default=DEFAULT_SPEED, help=f"Speed multiplier (default: {DEFAULT_SPEED})")
    p.add_argument("-l", "--lang", default="en-us", help="Language code (default: en-us)")
    p.add_argument("-o", "--output", help="Save to file instead of playing")
    p.add_argument("--no-wait", action="store_true", help="Start playback and return immediately (don't wait for audio to finish)")
    p.add_argument("--voices", action="store_true", help="List available voices")

    args = p.parse_args()

    playback_lock = None
    if args.no_wait:
        if os.fork() != 0:
            sys.exit(0)
        os.setsid()
        devnull = os.open(os.devnull, os.O_RDWR)
        for fd in (0, 1, 2):
            os.dup2(devnull, fd)
        os.close(devnull)
        # Acquire lock immediately to preserve invocation order
        LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
        playback_lock = open(LOCK_FILE, "w")
        fcntl.flock(playback_lock, fcntl.LOCK_EX)

    model_path, voices_path = ensure_model()
    kokoro = Kokoro(str(model_path), str(voices_path))

    if args.voices:
        list_voices(kokoro)
        return

    # Gather text from args or stdin
    if args.text:
        text = " ".join(args.text)
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
    else:
        p.error("No text provided. Pass text as arguments or pipe via stdin.")

    if not text:
        p.error("Empty text.")

    samples, sample_rate = kokoro.create(
        text, voice=args.voice, speed=args.speed, lang=args.lang
    )

    if args.output:
        sf.write(args.output, samples, sample_rate)
        print(f"Saved to {args.output}", file=sys.stderr)
    else:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            sf.write(f.name, samples, sample_rate)
            play(f.name)
            if playback_lock is not None:
                fcntl.flock(playback_lock, fcntl.LOCK_UN)
                playback_lock.close()


if __name__ == "__main__":
    main()
