---
name: extract-google-ai
description: Extract clean conversation text from Google AI Mode saved HTML files. Removes JavaScript, CSS, search results, and UI chrome to produce a readable transcript.
---

# Extract Google AI Mode Chat Sessions

Transforms a messy Google AI Mode HTML dump into a clean, readable conversation transcript.

## When to Use

- User has saved a Google AI Mode chat session as an `.html` file
- User wants to extract just the conversation text (user queries + AI responses)
- User mentions "trim chat session", "extract Google AI", "clean up HTML", or "chat transcript"

## What It Does

| Input | Output |
|-------|--------|
| 4-5 MB HTML file with JS, CSS, SVG, search results | 10-20 KB clean text transcript |
| Minified Google markup | Readable conversation flow |
| Duplicate content | Deduplicated, ordered transcript |

## Usage

```bash
node ~/.agents/skills/extract-google-ai/extract.js <input.html> [output.txt]
```

If `output.txt` is omitted, writes to `<input-basename>-trimmed.txt` in the same directory.

### Example

```bash
node ~/.agents/skills/extract-google-ai/extract.js chatsession.html
# Creates: chatsession-trimmed.txt
```

## Output Format

```
USER:
i want to build a software where
user send a receipt on telegram
...

Step 1: Set Up the Telegram Bot
You need a gateway to receive the receipts...

USER:
agreed. lets do it via metered prepaid credit model

Excellent. No expiry builds massive goodwill...
```

## How It Works

1. **Strips noise tags** — removes `<script>`, `<style>`, `<svg>`, `<meta>`, `<link>`, `<iframe>`, etc.
2. **Extracts user queries** — from `data-mq` attributes and `.iMqumd` DOM elements
3. **Extracts AI responses** — from headings (`.otQkpb`), paragraphs (`.n6owBd`), and code blocks (`<pre>`/`<code>`)
4. **Parses HTML comments** — Google stores raw content in `<!--TgQPHd||...-->` JSON comments
5. **Filters aggressively** — removes search result titles, URLs, tracking IDs, base64 images, UI labels
6. **Deduplicates** — eliminates exact and near-duplicate text while preserving order

## Prerequisites

- Node.js
- `cheerio` and `html-entities` packages (auto-installed on first run)

## Installing Dependencies

```bash
cd ~/.agents/skills/extract-google-ai && npm install
```

## Limitations

- Designed specifically for Google AI Mode HTML exports
- May need adjustment if Google changes their HTML structure
- Does not handle dynamic/JavaScript-rendered content (works on saved HTML files)
