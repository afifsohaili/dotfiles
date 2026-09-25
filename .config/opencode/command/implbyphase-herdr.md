---
description: Implement by phase with herdr panes (steerable workers)
---

Load the `herdr-orchestrate` skill. Then implement the todo items phase by phase by spawning a worker opencode session in a herdr pane instead of an opencode subagent:

- Split a sibling pane, start the worker with `herdr agent start --kind opencode -- --agent <AGENT> --model <MODEL>`.
- The worker must:
  - Load the tdd skill.
  - If test infrastructure exists, implement the TDD way using red-green-refactor.
  - MUST have feature specs (test input on API endpoint, verify output such as db records and response body is correct).
  - Use unit tests to cover the edge cases.
  - If planning docs are provided, update the planning doc once done. Update status and record any differences/divergences from the original plan.
  - Commit the code for this phase.
  - End its final message with a line exactly `<COMPLETE>`.
- Prompt the worker once with `herdr agent prompt <name> "<task> ... End your final message with a line exactly <COMPLETE>." --wait --timeout <MS>`.
- Read the worker's output, check for `<COMPLETE>`. Everything before it is the worker's summary — ingest it as context for the next phase.
- If `<COMPLETE>` is missing, re-check state and re-read once (delay 1 minute). If the worker is working again, wait more. If still idle with no `<COMPLETE>`, pause and ask the user: resume, re-prompt with a new direction, or abort. Never re-prompt automatically.
- The user may steer the worker directly in its pane at any time (send-keys, prompt). If interrupted, the sentinel check fails and you pause to ask.

If a phase is big, feel free to make multiple subphases.
At the end of all phases, run /review and review the code from phase 1 to phase N. Check the tests coverage if they are sufficient or if we're missing any.

$1
