# CODING_STANDARDS.md

Global defaults distilled from opencode session history (2025-10 → 2026-10, ~40 repos under `~/Projects` and `~/Tiga`). A project's own `AGENTS.md` overrides anything here. Before coding, read the repo's `AGENTS.md`, plus `CONTEXT.md` / `UBIQUITOUS_LANGUAGE.md` / `product.md` for agreed terms.

Sources: `~/.config/opencode/AGENTS.md`; repo `AGENTS.md` files (projexn, projexn2, grocerorv2, base-nuxt-app, base-laravel-app, base-adonis-app, aso-notes, aso-db, agent-webbridge, excalidraw-ai, jemputlah.my, playwriter, Peekaboo, fcpotradingtips, opencodehub); `~/.config/opencode/command/*.md`; subagent briefs and commit history across sessions.

## 1. Workflow: explore → plan → phases → review

- **Explore before implementing.** `/justshow`: show options and which parts change, run the user through each option with the question tool. No implementation until they pick. `/elaborate`: research via websearch MCP, STE100 language, concrete examples.
- **Planning artifacts live in `plans/<NNN>-<slug>/`** at repo root — never `.scratch/`. Zero-padded sequential number after the highest existing folder. Spec is `spec.md`; tickets are `issues/<NN>-<slug>.md`. Commit them.
- **Ticket shape.** `**Status:**` line near the top (`ready-for-agent`, `done`, …); `**Blocked by:**` for blocking edges; append notes under `## Implementation notes / divergences`.
- **Implement phase by phase** (`/implbyphase`): plan a todo list, then one subagent per phase. Each phase is small enough for one commit. Big phases split into subphases (e.g. 23a data layer → 23b reducer → 23c UI).
- **Close each phase by updating the plan doc**: status, what shipped, divergences from the plan, "next phase must-know notes". Record real divergences, not theater.
- **Review at the end**: two-axis review of phases 1..N; check test coverage sufficiency.

## 2. TDD and tests

- **Load the `tdd` skill before implementing.** If test infrastructure exists, implement red-green-refactor. No feature without tests.
- **Feature specs** test at the boundary: input → API endpoint → assert output (db records and response body correct).
- **Unit tests cover edge cases.** Integration tests are preferred over unit tests.
- **Self-contained tests.** No dependency on previous test data; create data with factories, not seeded rows.
- **Laravel tests**: use the `DatabaseTransactions` trait, not `RefreshDatabase`. Never call `$this->runMigrationsAndSeed()` in test files — it runs `migrate:fresh --seed` at ~2–3s per call. Create the schema once for the suite.
- **DB connection failures in tests**: prepend the project `DATABASE_URL` (exact URL in the repo's `AGENTS.md`).
- **Nuxt e2e tiers**: in-process transactional (default) → built-server → component. Use the repo test helpers (`test` from the testing package, `givenVerifiedUser()`, `fixtures.load()`, `queue` fixture). Never hand-roll sign-in or raw-SQL cleanup.
- **Whole suite**: `--parallel --processes=4 --no-coverage`.
- **Inspecting values in vitest**: `console.log` is swallowed — `throw new Error(JSON.stringify(value))`.
- **UI verification**: use the browser MCP (Playwriter, Kimi WebBridge, pencil) to verify behavior in a real browser.

## 3. Git and commits

- **Commit only when explicitly requested.** Default repo policy is NEVER COMMIT; phase-based tasks carry an explicit override. Never push unless asked.
- **One phase = one conventional commit.** Match the repo's `git log --oneline` style.
- Types in use: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `perf`, `chore`, `ci`. Module scopes: `feat(simulator):`, `fix(runboard):`, `feat(hub):`, `test(e2e):`, `ci(deploy):`.
- Plan/ticket commits carry the plan identifier: `docs(015-r): record review outcome…`, `plans: 016 phase 4a done`.
- **Stage only intended files.** Never `git add -A`. Never commit secrets, `.env*`, `node_modules`, another agent's WIP files, `design.pen`, or review reports unless asked.
- If `index.lock` collides with parallel agents: wait 5s, retry up to 3 times.

## 4. Code style

Cross-cutting:

- **No code comments unless explicitly requested. Never remove existing comments.** Enforced as a review standard in projexn/base-* work.
- Comment policy is per-repo: playwriter requires comments that preserve detailed prompt context; projexn forbids unrequested ones. The repo wins.
- **Follow existing patterns.** "Before implementing features, study existing codebase patterns. Do NOT introduce new patterns based on LLM training data."
- **Format every file you touch** before committing (Pint for PHP, Prettier or ESLint per repo).

TypeScript / Vue (Nuxt):

- projexn-style: Prettier + Tailwind plugin, 2-space indent, import sort via `@trivago/prettier-plugin-sort-imports` (order: `@core`, `@server`, `@ui`, relative).
- ESLint-only repos (aso-notes, aso-db, jemputlah.my): `@antfu/eslint-config` handles formatting; no Prettier.
- TypeScript strict. Explicit types on function params/returns. Avoid `any`; use `unknown`.
- Naming: camelCase functions/variables, PascalCase components/types, `use`-prefixed composables.
- Vue 3 Composition API with `<script setup lang="ts">`; `ref()` for primitives, `reactive()` for objects.
- Check the shared UI package first (`packages/web-ui`, `@monorepo/components`) before creating components. Custom prefix `Xn` in projexn.
- Icons: list the existing icon directory first; use `unplugin-icons` (`~icons/heroicons/cog-6-tooth`). No inline SVGs, no `<img>` icons.
- Tailwind classes only, no inline styles.
- State: Pinia for global state, TanStack Query for server state.
- API calls through the repo helper: `useApi()` / `buildFetchLib()` (Nuxt), `APIHelper.AdminNoAPI` (Laravel + Inertia) — never raw axios or `$fetch` in setup.
- Errors: try/catch, `error instanceof Error`, surface user-facing errors via the toast composable.
- File naming: kebab-case in newer templates (jemputlah.my, aso-db).

PHP / Laravel:

- `./vendor/bin/pint <files>` on all modified PHP files before commit. Find them: `git diff --name-only | grep '\.php$' | xargs -I {} ./vendor/bin/pint {}`.
- New controllers need routes in both `api.php` and `web.php`.

## 5. Architecture and patterns

- **Clean seams**: new features should be easily removable and loosely coupled — "it should be easily removable in the future."
- **Strategy + registry is the default seam for anything replaceable.** Whenever a piece might change — AI provider, storage backend, market-data provider, transcript source, billing gateway, auth source — put an interface behind a registry keyed by id, selected by config (env var or `app_settings`). Adding or swapping an implementation is a new class plus one registration line, never an edit to call sites.
  - Canonical shape: `interface.ts` (the strategy), `registry.ts` (register / get / list), one file per concrete provider (`openrouter.ts`, `r2.ts`, `commodities-api-adapter.ts`), a `fake.ts` for tests, registration at boot, and boot-time validation so a typo fails fast.
  - Real examples: `/Users/afifsohaili/Projects/grocerorv2/apps/web/server/lib/ai/interface.ts` + `registry.ts`; `/Users/afifsohaili/Projects/grocerorv2/apps/web/server/lib/storage/`; `/Users/afifsohaili/Projects/aso-notes/apps/web/server/lib/pipeline/registry.ts`; `/Users/afifsohaili/Projects/fcpotradingtips/apps/web/server/lib/market-data/registry.ts`.
  - Naming: `registerX` / `getX` / `listX`, or a `StageRegistry` class with `register` / `get` / `has`.
  - Selection: an env var (`MARKET_DATA_PROVIDER`) or a per-task settings row. Ship a disabled/`fake` provider for tests and deploy-safe defaults.
  - Add a test seam (`setXFetcher` / `resetXFetcher`) so tests never hit the real external service or clobber quota counters.
- **Adapter / facade / factory** are the same seam seen from different sides: an adapter wraps an external dependency; a factory builds the chosen implementation. Use them at every boundary the user might swap.
- **Pipeline with ordered stages**: register stages, reference by id, validate at boot.
- Prefer expressions: `.map/.filter/.reduce/.flatMap` over `for` loops; early returns; minimal nesting.
- Object arguments for functions with more than one parameter.
- Error wrapping via cause: `new Error("wrapping error", { cause: e })`. Never string-concat the cause. Never silently suppress errors.
- Node built-ins import module namespaces: `import fs from 'node:fs'`.
- No getters/setters for simple private fields — make the field public.
- Use `new URL(path, baseUrl)` for URL construction.
- Timezone: store timestamps in UTC; treat zone-less times as UTC; convert to display timezone at render.
- Security-sensitive headers: unresolvable context → default-deny, never guess.
- Runtime-changeable app config → DB settings table when the stack supports it.

## 6. Planning docs and domain language

- `UBIQUITOUS_LANGUAGE.md` / `CONTEXT.md` / `product.md` are canonical. Read them, use agreed terms with the user, and suggest updates when terminology or boundaries change.
- Issue tracker is local markdown under `plans/`. Specs, tickets, and divergences are committed with the code.

## 7. Agent orchestration

- **Parallelize independent work.** Spawn subagents for phases and disjoint surfaces. Two agents never share files — locale files and `git checkout` collisions are known failure modes.
- **Worker brief shape**: scope + exact files; constraints (`Do NOT change backend files`, `Do not touch unrelated files; do not reformat existing code`); required first step (load skill); gates to run before commit; commit message; report-back shape.
- **Report-back shape**: status; files changed; red output summary; green counts; commit hash; divergences. Keep it short (≤8 lines typical).
- Herdr-orchestrated workers end their final message with an exact `<COMPLETE>` sentinel. Missing sentinel → check state, re-read once; never auto-re-prompt — ask the user (resume, redirect, abort).
- Review tasks are read-only: "Report only; do not fix." Fixes happen in a separate phase.

## 8. Review standards

- Two axes, parallel subagents: **Standards** (repo conventions + Fowler smell baseline) and **Spec** (does it implement the plan/issue).
- Review the full change since the fixed point (`git diff <base>...HEAD`), not just the latest commit. Validate the fixed point and non-empty diff before spawning agents.
- Severity ladder: `blocker`, `risk`, `nit`, `question`. One finding = one bullet: severity, exact `file:line`, what is wrong, why it matters, the fix.
- Open with a verdict: `APPROVE` / `APPROVE WITH COMMENTS` / `CHANGES REQUESTED`.
- Reproduce or trace the failure path for every blocker/risk; state the exact triggering input.
- An empty finding list is a valid, good result. Do not invent problems to look thorough.
- The repo's documented standards override the smell baseline; tooling-enforced rules are skipped.

## 9. Debugging and runtime verification

- **Gather data, don't deduce.** `/debugging`: "Rather than trying to deduce what's wrong from the code, print console.log/debug statements everywhere relevant and see the values at runtime, then adjust."
- After TypeScript changes, run the package's `typecheck` (or `tsc`) — non-negotiable.
- Verify UI behavior in a real browser via MCP, not by reading code.

## 10. Security and secrets

- Never commit or log credentials, API keys, `.env` files, sessions/signatures. Double-check `git diff` before committing.
- opencode permissions deny reading `*.env`, `*.env.*`, `.env`; allow `.env.example` and `.env.playwright`.
- `rm` needs the full absolute path; bare `rm *` prompts for approval.

## 11. Communication

The full voice spec lives in `~/.config/opencode/AGENTS.md` (answer first, ≤15-word sentences, fixed vocabulary, no filler). Reports follow: **what changed, did it pass, what I run next.** Decisions offer at most two options plus a recommendation. English unless explicitly requested.
