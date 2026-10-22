# Dotfiles repository instructions

These rules add to the global contract in `~/.config/opencode/AGENTS.md`. Where they conflict, this file wins.

## Git

- Auto-commit completed work in this repo. Commit each coherent change once checks pass; do not wait for an explicit request.
- Never push unless asked.
- Conventional commits: `type(scope): subject`. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `perf`, `chore`, `ci`.
- One purpose per commit. Tests with the fix. Docs separate (`docs(...)`).
- Stage only intended files. Never `git add -A`. Never commit secrets, `.env*`, `node_modules`, or another agent's WIP files.
