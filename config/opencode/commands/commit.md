---
description: Commit changes atomically, with the triggering request as the why
---

Commit the current changes atomically.

1. Find the user message that requested the work being committed. It may be a later message, not the first. Write a one-sentence summary of that request.
2. Inspect `git status` and the full diff.
3. Split the changes into atomic commits. One purpose per commit. Never `git add -A`; stage only that commit's files.
4. Use conventional commits: `type(scope): subject`.
5. Add a body line: `Why: <summary of that request>`.
6. Run the repo's formatter, lint, and tests for the touched files before each commit.
7. Report every SHA, each commit's purpose, and any changes left uncommitted.

Never push. Never commit secrets, `.env*`, or unrelated WIP.
