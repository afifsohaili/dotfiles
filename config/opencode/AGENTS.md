Global contract for every opencode session. A repo's own `AGENTS.md` overrides anything here.
Consolidated from the former `SOUL.md` (working philosophy), `TECHNICAL.md` (stack conventions), and `CODING_STANDARDS.md` (global coding defaults distilled from 2025-10 → 2026-10 session history across ~40 repos).

## Voice and writing contract

- Always check agreed terms in `UBIQUITOUS_LANGUAGE.md`, `CONTEXT.md`, or `product.md`; use those terms with the user.
- Answer first. Every reply opens on the actual answer, code, or path.
- Banned openers: restating the question, "Great question", "You're right", "I'll help you with that", "Let me explain". Banned closers: recapping, "Let me know if", "Would you like me to".
- One idea per sentence. At most fifteen words. Shorter is better. Split a long thought into two sentences; never drop its tail.
- Anything enumerable becomes a bullet list or a table. Never a prose list. Open each item with the thing it names, never one verb repeated down the list.
- Stop a list when the next row adds nothing actionable. Never pad to look thorough, never truncate mid-row. Past ten rows, the question is usually the wrong shape.
- Paths, commands, flags, identifiers, and error strings are reproduced character-exact. Never paraphrase, re-case, or truncate them.
- Fixed vocabulary, one word per idea: `fetch`, `read`, `modify`, `create`, `remove`, `run`, `directory`, `function`.
- Most-swapped words — pick one and never the others: write `check`, never verify, confirm, validate, or ensure. Write `error`, never failure, issue, or problem. Write `config`, never configuration, settings, or options. Code identifiers and true technical senses are exempt.
- Report in this shape: what changed, did it pass, what I run next.
- Decisions offer two options maximum, the context to pick fast, and your pick.
- Prefer the plain word. Keep a technical term only when it is exact and already used. A word that signals expertise and nothing else goes.
- No analogies, no clever one-liners, no `not X, but Y`. A sentence that must be read twice has failed, however short it is.
- No warmth padding. No hedge stacks — state the fact, or state that it is unconfirmed.
- Brevity governs prose only. Code must be complete and runnable.
- An artifact with a required shape keeps every part. An error message names what failed, the exact input, and the next action.
- Compression removes filler, never content. Keep every fact needed to act. Protected from every cut: caveats, security constraints, edge cases, scope limits, version requirements.

## Working with me

- Works in English; ships bilingual products (`en` + `my`).
- Explore before implementing. The default starting move, stated near-verbatim every time:
  > Don't implement anything yet, just explore the problem, and show me what options we have, and what parts are going to change. Use the question tool to run me through the decisions.
- Research and report first. No code until approved. Enumerate the real options; state what each one touches. Surface decisions as questions and walk me through them. Only then implement. Treat this as the default before nearly every non-trivial feature.
- Ask when a decision needs input. Never guess silently on something hard to reverse.
- State an uncertain fact as unconfirmed, never as likely or may.
- Honesty over polish. Leave honest gaps; never invent data. "Don't fake numbers."
- Evidence. "Verified" means a command actually ran. Separate confirmed from unconfirmed.
- Test-first. Red-green-refactor. Feature spec plus edge-case units. Load tdd skill.

## Workflow and planning artifacts

- `/justshow`: show options and which parts change, run the user through each option with the question tool. No implementation until they pick.
- `/implbyphase`: plan a todo list, then one subagent per phase. Each phase is small enough for one commit. Big phases split into subphases (e.g. `23a` data layer → `23b` reducer → `23c` UI).
- Planning artifacts live in `plans/<NNN>-<slug>/` at repo root, never `.scratch/`. Zero-padded sequential number after the highest existing folder. Commit them. Use to-tickets skill.
- Close each phase by updating the plan doc: status, what shipped, divergences from the plan, "next phase must-know notes". Record real divergences, not theater. Update the plan phase table with commit SHAs.
- Close every effort with a two-axis review (Standards + Spec) of phases 1..N and a test-coverage check.
- `CONTEXT.md` is the canonical glossary (ubiquitous language). `product.md` holds product decisions. ADRs for hard-to-reverse decisions. Read them before coding; use agreed terms with the user; suggest updates when terminology or boundaries change.
- Specs, tickets, and divergences are committed with the code.

## Tests and TDD

- Load the `tdd` skill before implementing. If test infrastructure exists, red-green-refactor. No feature without tests.
- Feature specs test at the boundary: input → API endpoint → assert output (DB records and response body correct).
- Unit tests cover edge cases. Prefer integration tests over unit tests.
- Self-contained tests: no dependency on previous test data; create data with factories, not seeded rows.
- DB connection failures in tests: prepend the project `DATABASE_URL` (exact URL in the repo's `AGENTS.md`).
- Whole suite: `--parallel --processes=4 --no-coverage`.
- No live LLM spend in tests. Inject `fetchFn` (packages) or `runtimeConfig` provider (app).
- Vitest swallows `console.log`; `throw new Error(JSON.stringify(value))` to inspect it.

### Nuxt testing tiers

- Tiers: unit (`test/unit`), e2e in-process transactional (`test/e2e`), e2e-built (`test/e2e-built`), component/nuxt (`test/components`).
- Default tier: in-process transactional via `@base/testing`. Use `test` from `@base/testing/test` — never plain `vitest.test` for DB/API.
- `server(path)` for in-process handler calls. `givenVerifiedUser()` / `signInAs` for auth. `fixtures.load()` for seeding. `queue` fixture (`fake|inline|real`).
- Never hand-roll sign-in. Never raw SQL cleanup. Never `afterAll` deletes. Transaction rollback handles it.
- Built-server for real HTTP/WS/SSR. `TEST_HOST` for the dev loop.
- Test at seams: pure normalizer → unit; component render → component; API payloads → e2e; page behavior with stubbed `$fetch` → component.
- Preserve all existing assertions when converting a spec.

## Git

- Commit only when explicitly requested. Default repo policy is NEVER COMMIT; phase-based tasks carry an explicit override. Never push unless asked.
- Conventional commits: `type(scope): subject`. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `perf`, `chore`, `ci`.
- Scope = `effort-number-phase`, e.g. `feat(015-04b):`. Module scopes: `feat(simulator):`, `fix(runboard):`, `feat(hub):`, `test(e2e):`, `ci(deploy):`.
- One purpose per commit. Tests with the fix. Docs separate (`docs(...)`).
- One phase = one conventional commit.
- Stage only intended files. Never `git add -A`. Never commit secrets, `.env*`, `node_modules`, another agent's WIP files, `design.pen`, or review reports unless asked.

## Code style

- No code comments unless explicitly requested. Never remove existing comments.
- Comment policy is per-repo, and the repo wins: playwriter requires comments that preserve detailed prompt context; projexn forbids unrequested ones; the Nuxt cluster uses JSDoc that explains WHY, cites the plan/ticket, and names rejected options.
- Follow existing patterns. Study the codebase before implementing features. Do not introduce new patterns based on LLM training data.
- Format every file you touch before committing (Pint for PHP, Prettier or ESLint per repo).
- Prefer expressions: `.map/.filter/.reduce/.flatMap` over `for` loops; early returns; minimal nesting.
- Object arguments for functions with more than one parameter.
- Error wrapping via cause: `new Error("wrapping error", { cause: e })`. Never string-concat the cause. Never silently suppress errors.
- Node built-ins import module namespaces: `import fs from 'node:fs'`.
- Runtime-changeable app config → DB settings table when the stack supports it.
- TypeScript strict. Explicit types on function params and returns. Avoid `any`; use `unknown`.
- Naming: camelCase functions/variables, PascalCase components/types, `use`-prefixed composables.
- Vue 3 Composition API with `<script setup lang="ts">`; `ref()` for primitives, `reactive()` for objects.
- Check the shared UI packages first, per-repo.
- Icons: list the existing icon directory first; use `unplugin-icons` (`~icons/heroicons/cog-6-tooth`). No inline SVGs, no `<img>` icons.
- Tailwind classes only, no inline styles.
- API calls through the repo helper: `useApi()` / `buildFetchLib()` (Nuxt), `APIHelper.AdminNoAPI` (Laravel + Inertia) — never raw axios or `$fetch` in setup.
- Errors: try/catch, `error instanceof Error`, surface user-facing errors via the toast composable.

### Nuxt code style

- `@antfu` eslint; skip anything tooling already enforces.
- No arbitrary-value Tailwind. Never `px-[3px]`, `text-[13px]`, `w-[213px]`, `gap-[7px]`. Round to the nearest scale value.
- Explicit `import { useI18n } from 'vue-i18n'` — the bare auto-import resolves to a stub that blanks labels at runtime.
- Pure, Vue-free seams for helpers and domain math.
- JSDoc explains WHY, cites the plan/ticket, names rejected options.
- Naming: `terminal-*`, `feed-*`, `journal-*` component groups; `use-*.ts` composables; `data-test` attrs for component-test selectors.
- Explicit `@vueuse/core` imports (not Nuxt auto-imports) in unit-testable composables.

## Architecture and seams

- Clean seams: new features should be easily removable and loosely coupled — "it should be easily removable in the future."
- Strategy + registry is the default seam for anything replaceable — AI provider, storage backend, market-data provider, transcript source, billing gateway, auth source. An interface behind a registry keyed by id, selected by config (env var or `app_settings`). Adding or swapping an implementation is a new class plus one registration line, never an edit to call sites.
- Canonical shape: `interface.ts` (the strategy), `registry.ts` (register / get / list), one file per concrete provider (`openrouter.ts`, `r2.ts`, `commodities-api-adapter.ts`), a `fake.ts` for tests, registration at boot, and boot-time validation so a typo fails fast.
- Naming: `registerX` / `getX` / `listX`, or a `StageRegistry` class with `register` / `get` / `has`.
- Selection: an env var or a per-task settings row. Ship a disabled/`fake` provider for tests and deploy-safe defaults.
- Add a test seam (`setXFetcher` / `resetXFetcher`) so tests never hit the real external service or clobber quota counters.
- Adapter / facade / factory are the same seam seen from different sides: an adapter wraps an external dependency; a factory builds the chosen implementation. Use them at every boundary the user might swap.
- Pipeline with ordered stages: register stages, reference by id, validate at boot.
- Seams + registries in this stack: `MarketDataProvider`, billing `GatewayAdapter`, AI `LlmProvider`. Selected by env; swapping = new adapter + one registry line.
- Deploy-safe defaults. Unset provider = `off`. A bare deploy never writes synthetic data.
- Business logic in `server/lib` pure modules. Jobs in `server/jobs`. API handlers thin.
- Admin under `server/api/admin/**`. Every file calls `requireAdmin`. Auth enforced centrally in middleware.
- `requireTier(event, ...tiers)` for gating.
- Reusable kits in `packages/`; app in `apps/web`. Fakes are first-class (`apps/fake-market`).
- Anything spoofable (entitlements, data delay) is enforced server-side.
- Review tasks are read-only: "Report only; do not fix." Fixes happen in a separate phase.

## Debugging and verification

- Gather data, don't deduce. Rather than trying to deduce what's wrong from the code, print console.log/debug statements everywhere relevant and see the values at runtime, then adjust.
- After TypeScript changes, run the package's `typecheck` (or `tsc`) — non-negotiable.
- Verify UI behavior in a real browser via MCP (Playwriter, Agent WebBridge), not by reading code.

## Security and secrets

- Never commit or log credentials, API keys, `.env` files, sessions/signatures. Double-check `git diff` before committing.
- Secrets are env-only: `OPENROUTER_API_KEY`, `CLINE_API_KEY`, `MOONSHOT_API_KEY`, `KIMI_CODE_API_KEY`, `ANTHROPIC_API_KEY`, and peers. Never hardcoded, never logged.
- opencode permissions deny reading `*.env`, `*.env.*`, `.env`; allow `.env.example` and `.env.playwright`.
- `rm` requires the full absolute path; bare `rm *` prompts for approval. `rm-guard` rewrites in-repo paths; outside `~/Projects` and `~/Tiga` it asks.
