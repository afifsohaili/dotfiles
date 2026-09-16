---
name: herdr-orchestrate
description: Orchestrate coding agents in herdr panes instead of opencode subagents. Use when the user wants to spawn a worker opencode session in a pane, prompt it, wait for completion, read its summary, and steer it mid-run. Replaces the opencode `task` subagent flow when the user needs to interrupt or redirect the worker. Requires HERDR_ENV=1.
---

# Herdr Orchestrate

Spawn a worker opencode session in a herdr pane, prompt it once, wait for it to settle, read its final summary, and feed that summary back as context — the same information flow as an opencode subagent, but the worker lives in a real pane you can steer.

The orchestrator (A) runs in the calling pane. The worker (B) runs in a sibling pane. A never re-prompts B. A only ever sends the original prompt once.

## Verify environment

Before any control command, confirm this agent runs inside a herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say you are not running inside herdr and stop.

## The completion sentinel

B must end its final message with a line exactly:

```
<COMPLETE>
```

Everything before `<COMPLETE>` in B's final output is B's summary. A ingests that text as context, exactly like a subagent's returned message. The sentinel is the delimiter that tells A where the summary ends.

Never re-prompt B. If `<COMPLETE>` is missing, re-read B's state and output (see below), never resend the prompt.

## Orchestration flow

### 1. Split a sibling pane

Default to a sibling pane in the current tab, preserving the caller's working directory, keeping user focus in the calling pane:

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
worker_pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
```

### 2. Start the worker opencode session

```bash
herdr agent start <name> --kind opencode --pane "$worker_pane" -- --agent <AGENT> --model <MODEL>
```

- `<name>`: unique, matches `[a-z][a-z0-9_-]{0,31}`.
- `<AGENT>`: an agent defined in `~/.config/opencode/agent/*.md` (e.g. `ollama-k3`, `ollama-dsv4f`).
- `<MODEL>`: `provider/model` (e.g. `ollama-cloud/kimi-k3`). Read it from the agent file's `model:` frontmatter if not given explicitly.

`agent start` returns only after herdr detects opencode and marks it ready. If it returns `agent_not_ready`, wait until the agent is idle before prompting.

### 3. Prompt B once

```bash
herdr agent prompt <name> "<task> ... End your final message with a line exactly <COMPLETE>." --wait --timeout <MS>
```

`--wait` returns on the first settled `idle`, `done`, or `blocked` state. **This is not proof of completion** — herdr can report `idle`/`done` while B is still working (known bug herdr#3530). Always verify with a read.

If the prompt returns `agent_blocked`, B is at a question/permission dialog. Inspect it, ask the user before answering, then use `agent send-keys` to respond.

### 4. Read B's output

```bash
herdr agent read <name> --source recent-unwrapped --lines 200
```

If the read returns `agent_not_idle`, B is still working — wait and re-read.

### 5. Check for the sentinel

- `<COMPLETE>` found → everything before it is B's summary. Ingest it as context and proceed to the next phase.
- `<COMPLETE>` missing → B was interrupted or herdr falsely settled. Do NOT re-prompt. Re-check state and re-read once:

```bash
herdr agent get <name>
sleep 60
herdr agent read <name> --source recent-unwrapped --lines 200
```

- B is now `working` → it was a false settle. Wait for it to settle again, then re-read.
- B is still `idle`/`done` and still no `<COMPLETE>` → B was genuinely interrupted. Pause and ask the user: resume B, re-prompt with a new direction, or abort.

## Steering B directly

The user steers B directly in its own pane. A does not steer B. When the user interrupts B (e.g. ctrl+c), B drops to `idle` and A's wait returns. A's sentinel check then fails, and A pauses to ask the user what to do next. A never blindly proceeds.

Useful steering commands (run by the user or by A on request):

```bash
herdr agent send-keys <name> esc
herdr agent send-keys <name> ctrl+c
herdr agent prompt <name> "<new direction>" --wait --timeout <MS>
herdr agent read <name> --source recent-unwrapped --lines 120
```

## Safety rules

- Use `--no-focus` for background work unless the user asked to switch context.
- Use `--current`, an explicit pane ID, or a unique agent name. Do not rely on another client's focused pane.
- Parse IDs from JSON responses. Do not derive them from sidebar order.
- Do not close workspaces, tabs, panes, or sessions you did not create unless the user explicitly asked.
- A timeout or `agent_prompt_stalled` does not prove the prompt was never delivered. Read B before retrying to avoid submitting the same prompt twice.
- Never re-prompt B on a missing sentinel. Re-read state and output, then ask the user.
