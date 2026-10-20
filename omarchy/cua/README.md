# CUA Driver on Omarchy

Bounded, foreground Computer-Use Agent for OpenCode. Omarchy/Hyprland only; the
Mac does not load any of this.

## What runs

| Piece | Role |
| --- | --- |
| `omarchy/bin/cua-driver-mcp` | Discovers the Hyprland session, forces native Wayland + bounded mode, and execs `cua-driver mcp`. |
| `omarchy/cua/capability-manifest.yaml` | Deny-by-default allowlist. Currently Chrome only. |
| `config/opencode/plugins/cua-driver.ts` | Linux-gated V2 plugin that injects the MCP server. No-op on macOS. |

The MCP process owns the driver runtime. There is no daemon, socket, or
Hyprland plugin.

## Install

The wrapper expects the standalone driver at `~/.local/bin/cua-driver`. If it
is missing:

```bash
/bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"
```

Then link the wrapper:

```bash
bash install.sh
```

Reload the shared server once so it picks up the new plugin:

```bash
systemctl --user daemon-reload
systemctl --user restart opencode-server.service
```

The plugin loads when a session starts.

## Check

```bash
cua-driver doctor
cua-driver-mcp   # starts the stdio server; Ctrl-C to stop
```

`doctor` should report Wayland+XWayland and a reachable AT-SPI bus. The wrapper
exits with a clear error if the driver or manifest is missing.

## Use

Ask OpenCode to use the `cua-driver` tools. Start with `launch_app` for Chrome:
its result carries the `pid` and `window_id`. Pass that `pid` to `list_windows`;
global `list_apps` and `list_windows` are outside this manifest by design.

Pass `tree_format: "elements"` to `get_window_state` when you need
`element_token` values; the 0.36 default returns `tree_markdown` only.

Actions are foreground: the agent focuses Chrome and moves the real pointer.
This is expected without the experimental Hyprland plugin.

## Edit the allowlist

Add another app by its canonical absolute executable:

```yaml
resources:
  apps:
    - executable: /usr/bin/nautilus
      launch: true
      windows: all
      terminate: driver_launched
```

Keep `desktop.display: false`. Do not add `resources.browser.origins` together
with generic tools such as `click`, `type_text`, or `get_window_state`; CUA
refuses to start that mix.

## Security and limits

- Chrome runs with the real profile. The agent can read and act on any tab in
  that window, including logged-in sessions.
- Bounded mode caps the manifest at 24 hours. Restart OpenCode daily, or
  switch the wrapper to `standard` with the same manifest if that cadence is
  too strict.
- No terminal, file manager, or other app is in scope.
- Hyprland support is experimental. Background input and the second agent
  cursor require the Edge-only `cua-hyprland-plugin`, which is not installed.
- Chrome is Wayland-native here; native Wayland is enabled with
  `CUA_DRIVER_RS_ENABLE_WAYLAND=1` by the wrapper.

## Remove

Remove `config/opencode/plugins/cua-driver.ts`, or unlink
`~/.local/bin/cua-driver-mcp`, then restart OpenCode. The driver binary stays in
`~/.cua-driver`.
