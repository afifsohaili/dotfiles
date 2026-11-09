---
description: Implement by phase with subagents in worktrees
---

Before planning, check the repo has both skills:
- A verification skill.
- A worktree skill (for example `.agents/skills/worktree`).

If either is missing, stop and ask the user to install it. Do not orchestrate until both exist.

Plan a todo list with one phase per commit, and note which phases are independent. Then implement phase by phase by spawning a subagent per phase in its own worktree:

- Create the worktree with the worktree skill, and work only inside it.
- Load the tdd skill.
- If test infrastructure exists, you MUST implement this the TDD way using red-green-refactor.
- MUST have feature specs (test input on an API endpoint, check the output such as db records and response body is correct).
- Use unit tests to cover the edge cases.
- If planning docs are provided, update the planning doc once you are done with the task. Update status and record any differences/divergences from the original plan.
- Use the verification skill to check the phase works.
- Commit the code for this phase following `/commit`: run the formatter, lint, and tests for the touched files, use a conventional commit, and add the body line `Why: <one-sentence summary of this request>`. Never push.

Run independent phases in parallel, one worktree each, within the worktree skill's slot limit. Merge each phase branch back into the current branch as one commit per phase, then tear down its worktree.

If a phase is big, feel free to make multiple subphases.

$1
