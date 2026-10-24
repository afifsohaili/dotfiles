---
name: awb-keyword-planner
description: Read keyword demand from Google Ads Keyword Planner through the user's real Chrome via agent-webbridge — set any country (default Malaysia), pull monthly search ranges, bids and competition, and name the plan properly at the end. Use whenever a task needs Keyword Planner volumes without the Ads UI being driven by hand.
---

# Keyword Planner via agent-webbridge

Drive `https://ads.google.com/aw/keywordplanner/home?ocid=320418922&euid=327865438&__u=6472346862&uscid=320418922&__c=6970874778&authuser=0` in the user's logged-in Chrome. Read search demand, then rename the plan.

Verified 2026-10-24 against the live account.

## Rules

- Read-only except renaming the plan you created. Never click Create keywords, Save to campaign, Share, Download, or any campaign action.
- Keep the Malaysia/English/last-12-months defaults unless the task names another country; record the defaults used.
- Never convert a range ("1K – 10K") into a single number. Report values as displayed.
- One session per task (e.g. `keyword-planner`). Do not close the tab group.

## Setup

```bash
node ~/Projects/agent-webbridge/bin/awb.mjs status
node ~/Projects/agent-webbridge/bin/awb.mjs up "Default"   # if the daemon is down
```

All calls POST JSON to `http://127.0.0.1:10086/command` with `"session":"keyword-planner","profile":"Default"`.

If `evaluate`/`snapshot` hangs while `navigate` works, the extension debugger is wedged: run `awb connect "Default"` then `awb up "Default"` (Chrome restarts).

## Get volumes (verified path)

1. Open the Keyword Planner URL above with `newTab:true` and `group_title`.
2. Click the **"Get search volume and forecasts"** card: find the leaf element with that exact text and click its clickable ancestor (`BUTTON`/`A`/`role=button`).
3. A textarea appears. `fill` it with one keyword per line (max ~10 per batch):

```
{"action":"fill","args":{"selector":"textarea","value":"whatsapp forms\nwhatsapp crm"}}
```

4. Click **"Get started"** (same leaf-text/ancestor trick).
5. The plan page (`/keywordplanner/plan/keywords/historical?...&planId=...`) loads rows:
   `Keyword | Avg. monthly searches | Three month change | YoY change | Competition | Ad impression share | Top of page bid (low) | Top of page bid (high)`.
6. Read rows via DOM, not screenshots:

```js
[...document.querySelectorAll('[role=row],grid-row')]
  .map(r => r.innerText.replace(/\s+/g,' ').trim())
  .filter(t => /^keyword-ish/i.test(t))
```

Do **not** use "Discover new keywords": in automated sessions it returns "No suggestions found" (BotGuard). It also has its own separate location and language chips.

## Change the country (verified path)

The plan page has a targeting chip (`location_on Malaysia`). Clicking it opens the Location dialog. The dialog is a Google Ads material component: an a11y snapshot shows it as an empty `dialog`, so verify with a screenshot and DOM text.

**Include adds, it does not replace.** Include as many countries as the task needs, then save once. The chip renders the names joined with "and" (`location_on Indonesia and Singapore`).

1. Fresh `snapshot`; find `button` named `<current country>` (or `A and B` when several are set) and `click` its `@ref`. Refs go stale between snapshots — always re-snapshot right before clicking, and never reuse a ref after switching tabs.
2. In the dialog, tag the last visible `input` (the location search box; it has no placeholder) and fill it:

```js
const inputs = [...document.querySelectorAll('input')].filter(i => i.offsetParent)
const target = inputs[inputs.length - 1]
target.id = 'awb-loc-input'
// then fill #awb-loc-input with e.g. "Singapore"
```

3. Suggestions appear: `Singapore country`, `Singapore, Singapore city`, etc. Click the **Include** material button on the row whose label is `<Country> country` (first Include = first row). Repeat for every country to add.
4. **Only to replace** the previous country: delete its row in the selected list. Each selected row is a `tr.row` inside `location-display-list.included`; activate its remove cell directly:

```js
const row = [...document.querySelectorAll('tr.row')]
  .find(r => /Malaysia country/.test(r.textContent || ''))
row.querySelector('td.remove material-icon').click()
```

Skip this step to keep adding. If the list ends up empty, re-add the target country (step 2-3) before saving.
5. Save — **four "Save" texts exist in the DOM** (hidden quick-add, sharing and other dialogs). Click the one inside the geo picker:

```js
const save = [...document.querySelectorAll('*')]
  .find(e => e.children.length === 0 && (e.textContent || '').trim() === 'Save'
    && e.closest('.advanced-geopicker-editor-dialog-body'))
save.closest('material-button').click()
```

6. Verify the chip now reads `location_on <Country>` (or `A and B` for several) and the table numbers changed (Singapore `whatsapp crm` shows `+900%`, Malaysia `0%`).

## Name the plan (required before finishing)

A new plan is created on every "Get started"; the home list accumulates plans. Name the one you created:

1. Fresh `snapshot`; `click` the `button` named **Edit plan name**.
2. The last visible `input` holds `Plan from <date>...`; tag it, `fill` a proper name:

```
<Purpose> <YYYY-MM-DD> - <first keywords>
SEO daily 2026-10-24 - whatsapp forms, whatsapp crm
```

3. Click **Save inside the name popover** — not the other visible Saves. Walk up from the input until an ancestor contains a Save, then click that one:

```js
const inp = document.querySelector('#awb-plan-name')
let pop = inp
while (pop && ![...pop.querySelectorAll('*')].some(e => (e.textContent || '').trim() === 'Save')) pop = pop.parentElement
[...pop.querySelectorAll('*')]
  .filter(e => e.children.length === 0 && (e.textContent || '').trim() === 'Save' && e.offsetParent)[0]
  .closest('material-button').click()
```

4. Verify the breadcrumb: `Keyword Planner > <your name>`.

## Gotchas

- Refs (`@eNN`) are snapshot-scoped. Clicking a stale ref can silently target another tab; if the page jumps, `list_tabs`, capture the plan URL, `find_tab` with the full URL, then re-snapshot.
- `snapshot` on a material dialog can return an empty `dialog`; use `screenshot` (read the PNG) plus `document.body.innerText` instead.
- Location choices persist per plan. Changing the country reloads the same keywords — no need to re-enter them.
- Keep batches ≤10 keywords; larger batches slow the UI without improving data.
- Output format for reports: `keyword | avg monthly searches | 3-mo change | competition | top-of-page bid range`, with country + language + date range stated once above the table.
