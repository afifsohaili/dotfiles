---
description: Score phases 1..N on four axes and improve until 8.0
---

Load the `quality-loop` skill.

`$1` is free text. It may name the plans directory, a model, or extra constraints. Read it as instructions and apply what it says.

Use this thread's context to find phase 1..N and the plan doc. If more than one plan is in play, ask which one. If the context is absent, take the plans directory from `$1`. If that is absent too, stop and ask.

Before the first score:
- Check the plan doc exists and lists the phases.
- Check the working tree is clean.
- Run the repo's typecheck, lint, and tests where they exist. If they fail, stop: `/score` starts from a green baseline.

Then follow the `quality-loop` skill: spawn four read-only reviewer sessions in parallel, one per axis, plus one fixer session. Keep their session ids. Score, fix the weakest axis, re-score, and commit each improving cycle.

Stop at the skill's pass rule or stop rules. Append the scorecard to the plan doc. Report the final table, commits, and residual risks.
