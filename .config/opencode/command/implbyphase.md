---
description: Implement by phase with subagents
---

Plan a todo list, then implement the todo items phase by phase by spawning a subagent that:
- Load the tdd skill.
- If test infrastructure exists, you MUST implement this the TDD way using red-green-refactor.
- MUST have feature specs (test input on API endpoint, verify output such as db records and response body is correct) 
- Use unit tests to cover the edge cases
- If planning docs are provided, update the planning doc once you are done with the task. Update status and record any differences/divergences from the original plan.
- Commits the code for this phase.

If a phase is big, feel free to make multiple subphases.
At the end of all phases, pls run /review command and review the code from phase 1 to phase N. Check the tests coverage if they are sufficient or if we're missing any.

$1
