---
name: keyword-planner
description: Read keyword demand from Google Ads Keyword Planner through the user's real Edge via browse — set any country (default Malaysia), pull monthly search ranges, bids and competition, and name the plan properly at the end. Use whenever a task needs Keyword Planner volumes without the Ads UI being driven by hand.
---

# Keyword Planner via browse

Drive `https://ads.google.com/aw/keywordplanner/home?ocid=320418922&euid=327865438&__u=6472346862&uscid=320418922&__c=6970874778&authuser=0` in the user's logged-in Edge through the browse MCP. Read search demand, then rename the plan.

Workflow verified 2026-10-24 against the live account; selectors re-used unchanged on 2026-11-09.

## Rules

- Read-only except renaming the plan you created. Never click Create keywords, Save to campaign, Share, Download, or any campaign action.
- Keep the Malaysia/English/last-12-months defaults unless the task names another country; record the defaults used.
- Never convert a range ("1K – 10K") into a single number. Report values as displayed.
- One browse session per task (e.g. `keyword-planner`). Do not close its tabs.

## Setup

```bash
browse status   # expect connected: true, browser: edge-*
```

Through MCP, omit `session` on the first `execute`; browse creates your own session. Keep the whole task in that one session so the Ads tab and its transient dialogs survive between steps.

If a page hangs on a material dialog, re-read the page (`page.url()`, `document.body.innerText`) instead of retrying the click. If the Ads UI stops responding entirely, reload once, then stop and report.

## Get volumes (verified path)

1. `page.goto(<URL above>, { waitUntil: "domcontentloaded" })`. If Ads shows a logged-out page, call `handoff("Sign in to Google Ads, then continue")` and verify afterwards.
2. Click the **"Get search volume and forecasts"** card. Click the leaf element whose exact text is that label, then its clickable ancestor:

```js
const leaf = [...document.querySelectorAll("*")]
  .find(e => e.children.length === 0 && e.textContent.trim() === "Get search volume and forecasts");
leaf.closest("button, a, [role=button]").click();
```

3. A textarea appears. Fill it with one keyword per line (max ~10 per batch):

```js
await page.locator("textarea").last().fill("whatsapp forms\nwhatsapp crm");
```

4. Click **"Get started"** (same leaf-text/ancestor trick).
5. The plan page (`/keywordplanner/plan/keywords/historical?...&planId=...`) loads rows:
   `Keyword | Avg. monthly searches | Three month change | YoY change | Competition | Ad impression share | Top of page bid (low) | Top of page bid (high)`.
6. Read rows via DOM, not screenshots:

```js
return await page.evaluate(() =>
  [...document.querySelectorAll("[role=row], grid-row")]
    .map(r => r.innerText.replace(/\s+/g, " ").trim())
    .filter(Boolean)
);
```

Do **not** use "Discover new keywords": in automated sessions it returns "No suggestions found" (BotGuard). It also has its own separate location and language chips.

## Change the country (verified path)

The plan page has a targeting chip (`location_on Malaysia`). Clicking it opens the Location dialog. The dialog is a Google Ads material component: the accessibility tree can show it as an empty `dialog`, so verify with `document.body.innerText` or a screenshot.

**Include adds, it does not replace.** Include as many countries as the task needs, then save once. The chip renders the names joined with "and" (`location_on Indonesia and Singapore`).

1. Find the chip button by its accessible name (the current country, or `A and B` when several are set) and click it. Prefer a fresh `snapshot()` plus `ref(...)`; fall back to text matching when the chip is not in the snapshot.
2. In the dialog, fill the last visible `input` (the location search box; it has no placeholder):

```js
const inputs = await page.locator("input:visible").all();
await inputs[inputs.length - 1].fill("Singapore");
```

3. Suggestions appear: `Singapore country`, `Singapore, Singapore city`, etc. Click the **Include** button on the row whose label is `<Country> country` (first Include = first row). Repeat for every country to add.
4. **Only to replace** the previous country: delete its row in the selected list. Each selected row is a `tr.row` inside `location-display-list.included`; activate its remove cell directly:

```js
await page.evaluate(() => {
  const row = [...document.querySelectorAll("tr.row")]
    .find(r => /Malaysia country/.test(r.textContent || ""));
  row.querySelector("td.remove material-icon").click();
});
```

Skip this step to keep adding. If the list ends up empty, re-add the target country (step 2-3) before saving.
5. Save — **four "Save" texts exist in the DOM** (hidden quick-add, sharing and other dialogs). Click the one inside the geo picker:

```js
await page.evaluate(() => {
  const save = [...document.querySelectorAll("*")]
    .find(e => e.children.length === 0 && e.textContent.trim() === "Save"
      && e.closest(".advanced-geopicker-editor-dialog-body"));
  save.closest("material-button").click();
});
```

6. Verify the chip now reads `location_on <Country>` (or `A and B` for several) and the table numbers changed (Singapore `whatsapp crm` shows `+900%`, Malaysia `0%`).

## Name the plan (required before finishing)

A new plan is created on every "Get started"; the home list accumulates plans. Name the one you created:

1. Click the **Edit plan name** button.
2. The last visible `input` holds `Plan from <date>...`; fill it with a proper name:

```js
const inputs = await page.locator("input:visible").all();
await inputs[inputs.length - 1].fill("<Purpose> <YYYY-MM-DD> - <first keywords>");
```

Example: `SEO daily 2026-11-09 - whatsapp forms, whatsapp crm`.

3. Click **Save inside the name popover** — not the other visible Saves. Walk up from the input until an ancestor contains a Save, then click that one:

```js
await page.evaluate(() => {
  const inputs = [...document.querySelectorAll("input")].filter(i => i.offsetParent);
  const inp = inputs[inputs.length - 1];
  let pop = inp;
  while (pop && ![...pop.querySelectorAll("*")].some(e => e.textContent.trim() === "Save")) pop = pop.parentElement;
  [...pop.querySelectorAll("*")]
    .filter(e => e.children.length === 0 && e.textContent.trim() === "Save" && e.offsetParent)[0]
    .closest("material-button").click();
});
```

4. Verify the breadcrumb: `Keyword Planner > <your name>`.

## Gotchas

- Snapshot refs fail closed after navigation or DOM drift. Re-`snapshot()` before each click, or use role/text locators, which survive reloads.
- A material dialog can render as an empty `dialog` in `snapshot()`. Use `await page.locator("body").innerText()` or `screenshotWithLabels()` instead.
- Location choices persist per plan. Changing the country reloads the same keywords — no need to re-enter them.
- Keep batches ≤10 keywords; larger batches slow the UI without improving data.
- Output format for reports: `keyword | avg monthly searches | 3-mo change | competition | top-of-page bid range`, with country + language + date range stated once above the table.
