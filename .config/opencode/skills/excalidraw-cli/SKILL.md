---
name: excalidraw-cli
description: Create Excalidraw diagrams programmatically via CLI
license: MIT
compatibility: opencode
metadata:
  category: diagramming
---

# Excalidraw CLI

## Setup

```bash
# 1. Check server running
curl -s -o /dev/null -w "%{http_code}" http://localhost:3123
# 200 = OK, else ask user to start server + open browser

# 2. Get file UUID (required for -f flag)
excalidraw-cli list
# Output: myfile (249cb6e0-aec3-4d10-9e4b-7836300cec39) - use the UUID, not name
```

If no files listed: user must open http://localhost:3123 in browser.
If commands timeout: ask user to refresh browser page.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `list` | List connected files |
| `overview -f ID` | Spatial layout summary (run before adding) |
| `read -f ID --active` | List non-deleted elements |
| `add-rectangle -f ID` | Add rectangle |
| `add-text -f ID` | Add text |
| `add-arrow -f ID --from X --to Y` | Add arrow between elements |
| `add-frame -f ID -c el1 el2` | Group elements in frame |
| `update -f ID -i name` | Update element properties |
| `delete -f ID -i name` | Delete element |
| `export -f ID -o ./out.png` | Export to PNG/SVG |
| `to-markdown -f ID` | Convert to markdown |

## Commands

### Add Rectangle
```bash
excalidraw-cli add-rectangle -f <ID> -x 100 -y 100 --name box1 -t "Label" --background "#a5d8ff"
# Relative positioning:
excalidraw-cli add-rectangle -f <ID> --right-of box1 --name box2 -t "Next"
excalidraw-cli add-rectangle -f <ID> --below box1 --name box3
excalidraw-cli add-rectangle -f <ID> --inside box1 --name nested --gap 20
```

### Add Arrow
```bash
excalidraw-cli add-arrow -f <ID> --from box1 --to box2 -t "label"
# Arrows auto-bind to elements (follow when moved)
```

### Add Text
```bash
excalidraw-cli add-text -f <ID> -x 100 -y 50 -t "Title" --font-size 28
excalidraw-cli add-text -f <ID> --above box1 -t "Header"
# Multi-line: -t "Line1\nLine2"
```

### Add Frame
```bash
excalidraw-cli add-frame -f <ID> -c box1 box2 --name myframe --label "Section"
# Add to existing frame:
excalidraw-cli add-rectangle -f <ID> -x 100 -y 100 --name newbox --in-frame myframe
```

### Update
```bash
excalidraw-cli update -f <ID> -i box1 -x 200 -y 300           # position
excalidraw-cli update -f <ID> -i box1 -w 250 -h 150           # size
excalidraw-cli update -f <ID> -i box1 -t "New Label"          # text
excalidraw-cli update -f <ID> -i box1 --background "#ffc9c9"  # color
excalidraw-cli update -f <ID> -i box1 --right-of box2         # relative move
```

### Delete
```bash
excalidraw-cli delete -f <ID> -i box1 box2 box3  # accepts names or UUIDs
```

### Export
```bash
excalidraw-cli export -f <ID> -o ./diagram.png                    # PNG
excalidraw-cli export -f <ID> -o ./diagram.svg --format svg       # SVG
excalidraw-cli export -f <ID> -o ./section.png --frame myframe    # frame only
excalidraw-cli export -f <ID> -o ./hires.png --scale 2            # 2x resolution
```
**Always use `./` prefix** for output path to read file afterwards.

## Options

### Positioning
| Option | Description |
|--------|-------------|
| `-x <n> -y <n>` | Absolute position |
| `--right-of <name>` | Right of element |
| `--left-of <name>` | Left of element |
| `--below <name>` | Below element |
| `--above <name>` | Above element |
| `--inside <name>` | Inside element |
| `--gap <n>` | Spacing (default: 50, inside: 20) |

### Styling
| Option | Values |
|--------|--------|
| `--background <color>` | Fill color |
| `--stroke <color>` | Stroke color |
| `--stroke-style` | solid, dashed, dotted |
| `--fill` | solid, hachure, cross-hatch, zigzag |
| `--font-size <n>` | Text size (default: 20) |
| `--text-align` | left, center, right |
| `--vertical-align` | top, middle, bottom |

### Export
| Option | Description |
|--------|-------------|
| `-o <path>` | Output path (use `./`) |
| `--format` | png (default), svg |
| `--frame <name>` | Export specific frame only |
| `--scale <n>` | Scale factor (2 for retina) |
| `--no-background` | Transparent background |
| `--dark-mode` | Dark mode colors |

## Colors

| Color | Hex |
|-------|-----|
| Blue | `#a5d8ff` |
| Green | `#b2f2bb` |
| Yellow | `#ffec99` |
| Red | `#ffc9c9` |
| Purple | `#d0bfff` |
| Orange | `#ffd8a8` |
| Gray | `#dee2e6` |

## Key Rules

1. **Always run `overview` first** to see existing layout
2. **Always use `--name`** for elements you'll reference later
3. **Use `--gap 160`** between rectangles (720 if arrows have labels)
4. **Names work everywhere**: `-i`, `--from`, `--to`, `--right-of`, etc.
5. **Export to `./`** so you can read the file afterwards
6. **Bound text moves with shapes** automatically

## Example: Architecture Diagram

```bash
FILE_ID="uuid-from-list-command"

# Create boxes
excalidraw-cli add-rectangle -f $FILE_ID -x 100 -y 100 --name frontend -t "Frontend" --background "#a5d8ff"
excalidraw-cli add-rectangle -f $FILE_ID --right-of frontend --gap 160 --name api -t "API" --background "#b2f2bb"
excalidraw-cli add-rectangle -f $FILE_ID --right-of api --gap 160 --name db -t "Database" --background "#ffec99"

# Connect
excalidraw-cli add-arrow -f $FILE_ID --from frontend --to api -t "REST"
excalidraw-cli add-arrow -f $FILE_ID --from api --to db -t "SQL"

# Title
excalidraw-cli add-text -f $FILE_ID --above frontend -t "System Architecture" --font-size 28

# Export
excalidraw-cli export -f $FILE_ID -o ./architecture.png
```
