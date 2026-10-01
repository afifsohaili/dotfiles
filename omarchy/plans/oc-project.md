# oc-project: opencode directory picker

Status: **in progress** (Phase 1 done)

## Goal

`SUPER + SHIFT + O` opens an Omarchy-styled picker, lets the user choose a
target directory, then opens the shared opencode TUI on that directory. If a
window for that directory is already open, focus it instead of opening another.

Replaces the current static binding:

```lua
o.bind("SUPER + SHIFT + O", "Opencode", "omarchy-launch-tui --app-id=org.omarchy.opencode oc \"$HOME/Projects\"")
```

## Decisions (locked)

| Question | Decision |
| --- | --- |
| Picker UI | Omarchy menu `select` + `Other…` row that chains to `omarchy-menu-input` |
| Directory list source | opencode DB `project_directory` (recent first) + `fd -t d -d 1 ~/Projects`, deduped |
| Launch behavior | Same dir already open → focus it; else new window |
| Code location | New `omarchy/bin/oc-project` (install.sh already links `omarchy/bin`) |
| Keybinding | Replace `SUPER + SHIFT + O` |
| Window title | Full path (`oc: /abs/path`) |
| Resume | Keep `oc`'s `--continue` (resume last session in that dir) |

## Flow

1. `SUPER + SHIFT + O` → `oc-project`
2. Build rows: recent opencode dirs + `~/Projects` dirs.
3. `omarchy-menu-select "Open opencode in…"` with an `Other…` row first.
4. `Other…` → `omarchy-menu-input "Directory"` → typed path (`~` expanded).
5. Resolve picked path → directory, canonical.
6. If an `org.omarchy.opencode` window's opencode child has `--dir <that path>`,
   focus it and exit.
7. Else launch: `omarchy-launch-tui --app-id=org.omarchy.opencode oc "<path>"`
   with the terminal titled `oc: <path>`.

## Same-dir detection

opencode overwrites the window title via OSC, so no dir can be read from
`hyprctl clients` titles. Detection instead walks the process tree:

1. `hyprctl clients -j` → entries with `.class == "org.omarchy.opencode"`
   → `.pid` (terminal) and `.address`.
2. `/proc/<pid>/task/<pid>/children` → opencode child pid(s).
3. `/proc/<child>/cmdline` → contains `--dir <path>`.
4. Match canonical path → `hyprctl dispatch hl.dsp.focus({window:"address:<addr>"})`
   (fallback `hyprctl dispatch focuswindow address:<addr>`).

Verified on this machine: child cmdline is
`opencode attach http://127.0.0.1:15001 --dir /home/afifsohaili/Projects --continue`
and foot gives each window its own pid.

## Files

| File | Change |
| --- | --- |
| `omarchy/bin/oc-project` | New: picker + same-dir focus + launch |
| `omarchy/hypr/bindings.lua` | Repoint `SUPER+SHIFT+O` at `oc-project` |
| `omarchy/bin/oc` | Unchanged |
| `omarchy/tests/` | New: bash test harness + unit/feature tests |

## Testability constraints

The script must be testable without a real shell/Hyprland/opencode. Design for
injectable seams via environment variables:

- `OC_PROJECT_HYPRCTL` — command used instead of `hyprctl` (fixture: outputs JSON)
- `OC_PROJECT_MENU_SELECT` — command used instead of `omarchy-menu-select`
- `OC_PROJECT_MENU_INPUT` — command used instead of `omarchy-menu-input`
- `OC_PROJECT_LAUNCH` — command used instead of `omarchy-launch-tui`
- `OC_PROJECT_PROJECTS_DIR` — instead of `$HOME/Projects`
- `OC_PROJECT_OPENCODE_DB` — instead of the opencode sqlite path
- `OC_PROJECT_PROC_ROOT` — instead of `/proc` (fixture tree)

## Phases

### Phase 1 — test harness + list builder (DONE)
- Minimal bash test harness (`omarchy/tests/run.sh`, `omarchy/tests/lib.sh`).
- `oc-project list` subcommand: emit deduped dir rows from DB + Projects dir.
- Unit tests: dedup, missing dirs dropped, missing DB tolerated, missing
  Projects dir tolerated, ordering (recent first).
- Landed: `omarchy/bin/oc-project`, `omarchy/tests/{run.sh,lib.sh,oc_project_list_test.sh}`.
  Run with `omarchy/tests/run.sh`; 1 file / 21 assertions, all passing.

### Phase 2 — picker orchestration
- `oc-project pick` / default flow: menu-select rows + Other → menu-input.
- Unit tests with fake menu commands: preset pick, Other-then-input pick,
  cancel at select, cancel at input, empty input, `~` expansion, relative path.

### Phase 3 — same-dir detection + focus
- `oc-project focus <dir>`: walk proc tree, match `--dir`, focus via hyprctl.
- Unit tests with fixture `/proc` tree + fake hyprctl: match found, no match,
  multiple windows, non-opencode window ignored, cmdline without `--dir`.

### Phase 4 — launch + binding
- `oc-project open <dir>`: launch-tui with title + `oc <dir>`.
- Unit test with fake launch command: correct argv.
- Repoint `SUPER+SHIFT+O` in `bindings.lua`.
- Feature test: end-to-end with all fakes — pick existing open dir focuses;
  pick unopened dir launches with expected argv.

### Phase 5 — review pass
- Full-suite run, coverage check, update this doc's divergence log.

## Divergence log

### Phase 1
- Projects source uses a bash glob (`"$PROJECTS_DIR"/*` + `sort`) instead of
  `fd -t d -d 1`; avoids depending on `fd` and matches the no-new-deps rule.
- Hidden basenames (leading `.`) are skipped from BOTH sources, per the
  general skip rule; the doc only mentioned it for the Projects walk.
- `omarchy/tests/run.sh` accepts an optional substring filter argument to run
  a subset of test files; not in the original plan.
- Unknown subcommands exit non-zero with a message on stderr; the plan did not
  specify this.
