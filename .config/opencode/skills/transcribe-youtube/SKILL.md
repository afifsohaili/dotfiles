---
name: transcribe-youtube
description: Transcribe YouTube videos to text using local whisper.cpp (Metal GPU, large-v3). Use when the user wants to transcribe a YouTube video, extract text from a video, get subtitles from a video URL, or mentions "transcribe YouTube", "video to text", "audio transcription", or "get captions from video".
license: MIT
compatibility: opencode
metadata:
  category: transcription
---

# Transcribe YouTube Videos

Transcribe any YouTube video to text using whisper.cpp with Metal GPU acceleration (large-v3 model). Runs fully offline after the audio is downloaded.

## Prerequisites (one-time setup)

- `yt-dlp` installed (`pip install yt-dlp` or `brew install yt-dlp`)
- `ffmpeg` installed (`brew install ffmpeg`)
- `whisper-cli` in your PATH (symlinked to `~/.local/bin/whisper-cli`)
- Model at `~/.cache/whisper/models/ggml-large-v3.bin`
- `transcribe-youtube` script in your PATH (at `~/.local/bin/transcribe-youtube`)

## Quick usage

### Wrapper script (recommended)

```bash
# Transcribe to stdout
transcribe-youtube "https://www.youtube.com/watch?v=..."

# Save to file
transcribe-youtube "https://www.youtube.com/watch?v=..." transcript.txt

# Force Malay language
transcribe-youtube "https://www.youtube.com/watch?v=..." - | WHISPER_LANG=ms
```

### Manual pipeline (full control)

If you need custom ffmpeg flags, specific audio segments, or other tweaks, run the steps directly:

```bash
# 1. Extract audio
yt-dlp -x --audio-format wav -o "audio.%(ext)s" "YOUTUBE_URL"

# 2. Convert to 16 kHz mono (required by Whisper)
ffmpeg -i audio.wav -ar 16000 -ac 1 -c:a pcm_s16le audio_16k.wav

# 3. Transcribe with GPU
whisper-cli \
  -m ~/.cache/whisper/models/ggml-large-v3.bin \
  -f audio_16k.wav \
  -l auto \
  -otxt -of transcript
```

## Output formats

| Flag | Output |
|------|--------|
| `-otxt` | Plain text (default) |
| `-ovtt` | WebVTT with timestamps |
| `-osrt` | SRT subtitles |
| `-oj` | JSON with word-level timestamps |
| `-ojf` | Full JSON with metadata and confidence scores |

Example: get subtitles with timestamps
```bash
whisper-cli -m ~/.cache/whisper/models/ggml-large-v3.bin -f audio_16k.wav -l auto -osrt -of subs
cat subs.srt
```

## Language-specific tips

**Malay** (`-l ms`) — Standard spoken Malay works well. Colloquial dialects may drop words or mix in English.

**Arabic (Quran / Hadith)** (`-l ar`) — Whisper knows modern Arabic. Classical Quranic pronunciation often hallucinates or modernizes vocabulary. For religious content, treat the output as a draft and verify Arabic text against a trusted source.

**Code-switching** — If a speaker mixes Malay + Arabic loanwords in one sentence, `-l auto` usually picks Malay. Arabic segments may be transliterated or approximated.

## Quality control

| Problem | Fix |
|---------|-----|
| Repetitions during music / silence | Trim non-speech segments before transcribing, or use `-mc 0` to limit context window |
| Wrong language detected | Force with `-l ms`, `-l ar`, `-l en`, etc. |
| Slow processing | Already using Metal GPU. For faster results, use `ggml-large-v3-turbo.bin` (swap model path) |
| Hallucinated words on noisy audio | Pre-process with a noise gate or VAD (voice-activity detection) |

## Environment variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `WHISPER_MODEL` | Path to GGML model | `~/.cache/whisper/models/ggml-large-v3.bin` |
| `WHISPER_LANG` | Language code for transcription | `auto` |

## Tips for agents

- Always use the **wrapper script** (`transcribe-youtube`) for simple one-off transcriptions.
- Fall back to **manual steps** only if the user needs custom ffmpeg flags, specific time segments, or multiple output formats.
- For long videos (> 30 min), consider splitting into chunks to avoid memory spikes, or use `ggml-large-v3-turbo.bin` for faster throughput.
- If the user wants both `.txt` and `.srt`, run the manual pipeline twice with different `-o*` flags, or use `-ojf` and parse the JSON.
