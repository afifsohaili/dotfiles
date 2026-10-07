---
description: Stop loops started with /loop. Pass an id to stop just one, or no arguments to stop every loop in this session.
---
Stop recurring loops in this session.

Arguments: $ARGUMENTS

Rules:
- If an argument is given, call the stop_loop tool with it as `id` (the tool accepts the full id or an unambiguous prefix of 8+ characters).
- If no argument is given, first call list_loops, then stop every loop it lists by calling stop_loop once per id. If it lists none, say so.
- Report the outcome briefly. Do not call any other tools.
