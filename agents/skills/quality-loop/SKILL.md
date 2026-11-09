---
name: quality-loop
description: "Score code from phase 1..N on spec coverage, maintainability, implicit state, and security. Fix the weakest axis and re-score until the target passes. Use when the user runs /score or asks to raise code quality to a numeric threshold."
---

# Quality loop

Score the cumulative diff on four axes, fix the weakest one, re-score. Stop at the target or a stop rule.

## Pass rule

- Average >= 8.0.
- Security >= 8.
- No axis below 7.

Scores are integers from 0 to 10. The average is the plain mean of the four axes.

## Inputs

- The plan doc for phases 1..N, or the plans directory named in `$1`.
- The spec: plan doc, ticket, or issue.
- Repo standards: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `CODING_STANDARDS.md`, ADRs.
- The diff from the parent of phase 1 to `HEAD`, using the phase table in the plan doc.
- Deterministic check output.

If the spec is missing, stop. A score without a spec is not spec coverage.

## Axes

### 1. Spec coverage

Question: does the diff implement every requirement in the spec, and nothing outside it?

| Score | Anchor |
|---|---|
| 10 | Every requirement traces to code and a test that fails without the change. No scope drift, no unrequested behavior. |
| 8 | Every requirement covered. One or two weak tests, or a minor unrequested extra. |
| 6 | Core requirements covered. One material requirement missing or untested, or a noticeable unrequested change. |
| 4 | A major requirement missing, or a feature without a boundary test. |
| 0 | No traceability, wrong feature, or the diff contradicts the spec. |

Evidence: requirement id, `file:line`, test name. Number the requirements first if the spec has no ids.

### 2. Maintainability

Question: can another agent change this code without reading the whole module?

| Score | Anchor |
|---|---|
| 10 | Deep modules, clear seams, no duplication, small functions, easy to delete. Repo standards fully pass. |
| 8 | Repo standards pass. One minor duplication or a slightly large function. New code fits existing patterns. |
| 6 | Works, but needs navigation. Repeated logic, mixed responsibilities, or a hidden dependency. |
| 4 | God file, tangled coupling, duplicated logic, or a new pattern that contradicts the repo. |
| 0 | Unmaintainable. Any change risks breaking unrelated behavior. |

Evidence: `file:line`, function length, complexity when available, duplication, lint and typecheck output.

### 3. Implicit state

Question: is every piece of mutable state owned, bounded, and visible?

State includes globals, singletons, caches, env reads, module-level values, request context, derived values, lifecycles, and hidden I/O.

| Score | Anchor |
|---|---|
| 10 | Every mutable state has one owner. Invariants enforced at one boundary. Side effects explicit. No hidden globals or ambient config reads. Lifecycle clear. |
| 8 | One minor hidden default or env read. No correctness risk. |
| 6 | Shared mutable state with an unclear owner, or an invariant enforced in several places. Some hidden side effects. |
| 4 | Global mutable state, hidden I/O in pure-looking code, implicit ordering, or race risk. |
| 0 | Uncontrolled global state or hidden coupling makes behavior unpredictable. |

Evidence: state inventory (name, owner, lifetime, enforcement), call sites, tests. A fix either removes the hidden state or makes its owner and lifecycle explicit.

### 4. Security

Baseline: OWASP ASVS L1/L2 for the diff, plus the OWASP Secure Code Review checklist.

| Score | Anchor |
|---|---|
| 10 | No findings. Authn, authz, input validation, secrets, crypto, logging, and dependencies pass on the diff. Least privilege. |
| 8 | No high or critical. Low findings only, or a documented false positive. |
| 6 | Medium finding, missing hardening, or a sensitive path without a test. |
| 4 | High finding, missing authorization on a new path, or a secret in code or logs. |
| 0 | Critical or exploitable: injection, auth bypass, exposed secret, unsafe deserialization, or RCE. |

Evidence: CWE or ASVS id, `file:line`, exploit path, tool output. Deterministic scans take precedence over model judgment.

## Deterministic checks

Discover commands from `package.json`, `Makefile`, `mise.toml`, and `AGENTS.md`.

- Run typecheck, lint, and tests where they exist.
- Run the repo's existing secret scan, SAST, and dependency audit.
- Do not install tools during the loop.
- A missing check is noted, not invented.
- A red check caps the affected axis at 4 until green.

The judge cannot override a red check.

## Reviewer protocol

Spawn four reviewer subagents, one per axis. They are read-only.

- Cycle 1: create one session per axis and record each session id.
- Cycle 2 and later: send a follow-up to the same session with the new diff and tool output.
- Keep the fixed prompt prefix identical across cycles: rubric, repo standards, spec. Put the diff and tool output in the suffix. This is what makes prompt caching work.
- The reviewer sees the diff and tool output, never the fixer's summary or rationale.
- The reviewer re-scores from scratch. It ignores its previous score.
- An unchanged diff returns the same score with `"unchanged": true`. Do not re-roll.
- No evidence caps the score at 4.

`axis` is one of `spec`, `maintainability`, `implicit_state`, `security`. `severity` is one of `critical`, `high`, `medium`, `low`.

Each reviewer returns one JSON object:

```json
{
  "axis": "security",
  "score": 7,
  "evidence": ["src/auth.ts:42", "ASVS v5.0.0-8.2.1"],
  "findings": [
    {
      "severity": "high",
      "file": "src/auth.ts",
      "line": 42,
      "criterion": "authorization checked server-side per object",
      "fix": "call requireOwner before loading the record"
    }
  ],
  "unchanged": false
}
```

Return findings even when the score is 8 or higher. The next cycle may need them.

### Reviewer prompt

Fixed prefix, identical every cycle:

```
You are the <axis> reviewer. You are read-only.
Rubric: <axis anchors>
Repo standards: <files>
Spec: <requirements>
Score from scratch. Ignore any previous score.
Return one JSON object in the required shape. Quote evidence for every score.
```

Variable suffix, new every cycle:

```
Diff: <git diff>
Tool output: <typecheck, lint, tests, scans>
```

Put the prefix first so the provider can cache it. Never put the fixer's summary in either part.

## Fixer protocol

Use one persistent fixer session for the whole loop.

- It receives the selected findings, the spec, repo standards, the current diff, and any constraints in `$1`.
- It loads the `tdd` skill for behavior changes.
- It fixes at most three findings per cycle.
- It keeps the diff small.
- It never edits the rubric, the spec, or the plan doc. The orchestrator appends the scorecard.
- It never deletes or skips tests, disables lint, suppresses security tools, or adds a test that cannot fail.
- Every fix maps to a finding or a spec requirement.

## Loop

1. Gate: plan doc exists, tree clean, baseline checks recorded.
2. Score all four axes. Record the baseline.
3. If the pass rule holds, stop.
4. Pick the weakest axis. Tie-break order: security, spec coverage, implicit state, maintainability. Security blockers always preempt.
5. Select the top three findings by severity, then by points to the next anchor.
6. Fix with the persistent fixer session.
7. Run the deterministic checks. If red, fix before scoring. If still red after one attempt, discard the cycle and report.
8. Re-score all four axes with the same reviewer sessions.
9. Commit only if the average improves and no floor regresses. Use a conventional commit with this body. Never push.

```
Why: <one-sentence summary of the /score request>
Scores: spec X->Y, maintain X->Y, implicit X->Y, security X->Y (avg X->Y)
```

10. If the average is flat or drops, or a floor regresses, discard the cycle. Record `CYCLE_BASE=$(git rev-parse HEAD)` before the fix, then `git reset --hard "$CYCLE_BASE"` and remove only the new files the fixer created. The tree was clean at the gate, so only the cycle is at risk. Never run `git clean -fd` on the whole repo.
11. Repeat.

## Stop rules

Stop on the first rule that applies:

- Pass rule holds.
- Five cycles completed.
- Two consecutive cycles gain less than 0.25 average.
- The same finding stays after two fix attempts.
- A fix needs a spec change, product decision, or new dependency.
- Security regresses below 8.
- The user interrupts.

Return the best state, not necessarily the last one. Report why the loop stopped.

## Report

Append this section to the plan doc. Never rewrite the rest of the plan doc.

```md
## Quality loop — YYYY-MM-DD

| Cycle | Spec | Maintainability | Implicit state | Security | Avg | Result |
|---|---|---|---|---|---|---|
| 0 | 6 | 7 | 5 | 8 | 6.5 | baseline |
| 1 | 7 | 7 | 6 | 8 | 7.0 | keep |

Discarded cycles are listed with `discard` and no commit.

Final: PASS | STOPPED
Commits: <sha> ...
Residual risks: ...
Next: ...
```

Report the final table, the commits, and the residual risks.

## Model and persistence

- `$1` is free text. It may name a model, a plans directory, extra constraints, or a different cycle cap.
- If it names one model, pass it to all five subagents. If it names separate models, use them as named. Otherwise inherit the session model.
- `$1` cannot lower the pass rule.
- Keep the reviewer and fixer session ids for the whole loop.
- If a session is lost, spawn a new one and note the cache miss.

## Anti-gaming

- No rubric edits to raise a score.
- No test deletion, skip, or trivial assertion.
- No lint or type suppression.
- No security tool suppression.
- No scope padding.
- No re-scoring unchanged code.
- No fixing the scorer.
- If a score cannot improve without changing the spec, stop and ask.
