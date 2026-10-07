---
description: Schedule a recurring prompt that fires inside this session (e.g. `/loop 5m check the deploy`).
---
Call the start_loop tool once to schedule a recurring prompt in this session.

Arguments: $ARGUMENTS

Rules:
- If the first word is a number followed by m, h, or d (e.g. `5m`, `2h`, `1d`), pass it as `interval` and the rest of the text as `prompt`.
- Otherwise pass the whole argument as `prompt` and omit `interval` (it defaults to 5m).
- After the tool returns, report its confirmation to the user in one or two lines. Do not call any other tools.
