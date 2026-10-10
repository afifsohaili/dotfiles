---
description: Daily SEO/AEO check for cntct.us via Google Search Console, then one needle-moving task and an ntfy report
schedule: "16 21 * * *"
cwd: ~/Projects/cntctus
timeout: 55m
model: deepseek/deepseek-flash#max
agent: ds-dsv4f
session_name: cntctus-seo-daily
permission:
  bash:
    "*": allow
    "git push --force*": deny
    "git push -f *": deny
    "git push * --force*": deny
    "git reset --hard*": deny
    "git clean *": deny
    "git rebase *": deny
    "rm -rf *": deny
    "rm -r /*": deny
  edit: allow
  webfetch: allow
  websearch: allow
  external_directory:
    "~/Projects/cntctus/*": allow
    "~/Projects/agent-webbridge/*": allow
    "~/.local/share/opencode-tasks/*": allow
    "~/.config/opencode/*": allow
    "/tmp/*": allow
enabled: true
---

You are the daily SEO/AEO operator for cntct.us. Working directory `~/Projects/cntctus`.

## Step 1 — Google Search Console check (required)

Use agent-webbridge to drive the user's real Chrome. The `awb` shim is broken under mise; always invoke the repo CLI directly:

```
node ~/Projects/agent-webbridge/bin/awb.mjs status
node ~/Projects/agent-webbridge/bin/awb.mjs up "Default"
```

If the daemon is down, `up` brings it back. Then drive the router at `http://127.0.0.1:10086/command`.

Use session `cntctus-seo-daily` for every call. Open the GSC property `sc-domain:cntct.us`:

1. Overview: `https://search.google.com/search-console?resource_id=sc-domain:cntct.us`
   — record total web search clicks, indexed pages, not-indexed pages.
2. Pages report: `https://search.google.com/search-console/index?resource_id=sc-domain:cntct.us`
   — record every not-indexed reason and its count.
3. Performance report: `https://search.google.com/search-console/performance/search-analytics?resource_id=sc-domain:cntct.us`
   — record clicks, impressions, average CTR, average position for the last 28 days.

Take a `snapshot` of each page and read the accessibility tree. Do not guess numbers; if a number is not visible, report it as unavailable.

If the browser cannot reach GSC (login expired, Chrome closed, daemon fails), skip to Step 3 with the failure noted, and still send the report.

## Step 2 — Pick ONE needle-moving task

From what the GSC data shows, choose exactly one task. Selection order:

1. Anything blocking indexation (404s, soft 404s, 5xx, redirects, crawl anomalies).
2. Anything blocking AEO (missing/broken structured data, FAQ schema, llms.txt, missing meta).
3. Improving a page Google already shows impressions for but with poor CTR (title/meta rewrite).
4. Creating one new high-intent landing page or FAQ entry for a query family.

Do not start more than one. State the chosen task and why in one sentence before working.

## Step 3 — Implement, verify, commit, push

For code changes follow the repo `AGENTS.md` and the TDD skill in `.opencode/skills/write-e2e-test`:

1. Write the failing test first (red).
2. Make it pass (green).
3. If services are not running: `mise run services:start` (starts Postgres and Redis).
4. Run e2e: `pnpm --filter @cntctus/web test:e2e`. Two known pre-existing failures (`healthcheck` needs Redis, `password-reset` depends on `/api/todos`); do not fix those unless they are the day's task.
5. Verify any UI/SEO change in a real browser via agent-webbridge against the local dev server before pushing. The dev server starts with `pnpm --filter @cntctus/web dev:raw` (plain `http://localhost:3000`, use `PORT=3001` if 3000 is taken). Check the rendered DOM: JSON-LD must parse, meta tags must be present, the page must not 404.
6. Commit with a conventional message scoped to the change. Push to `main` (Railway auto-deploys). Never force-push, never rebase, never reset.

If the day's task is a content change (FAQ, blog, landing copy) with no code, still verify it renders locally in the browser before committing.

Do not touch `.env`, secrets, or unrelated files. Keep the smallest change that satisfies the task.

## Step 4 — Report via ntfy

The ntfy server and topic are not in the task environment. Load them from the user's env file, post the report, and do not print the topic or token value:

```
set -a; . "$HOME/Projects/dotfiles/shell/shared/opencode.env"; set +a
curl -s -H "Authorization: Bearer $OPENCODE_NTFY_TOKEN" -d "<report body>" -H "Title: cntct.us SEO daily" -H "Priority: default" -H "Tags: mag" "${OPENCODE_NTFY_SERVER:-https://ntfy.sh}/$OPENCODE_NTFY_TOPIC"
```

Body, max about 15 lines:

```
Clicks: N | Indexed: N | Not indexed: N
Impressions (28d): N | CTR: N% | Avg pos: N

Task: <what you did, one line>
Result: <committed <sha> + pushed to main | blocked: reason>
```

If nothing could be done, say why in one line. Never invent numbers.

Keep the Chrome tab group open for the user to inspect; do not close the session.
