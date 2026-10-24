# Setup

1. git clone to ~/Projects/dotfiles
2. install homebrew
3. `brew bundle install --file ~/Projects/dotfiles/Brewfile`
3. `asdf plugin add ruby`
3. `asdf plugin add nodejs`
3. `asdf plugin add python`
3. `asdf plugin add postgres`
3. `asdf plugin add redis`
4. ln -s $HOME/Projects/dotfiles/tmux/tmux.conf $HOME/.tmux.conf
5. ln -s $HOME/Projects/dotfiles/starship/starship.toml $HOME/.config/
6. Install oh my zsh
7. Install opencode v2 (`curl --proto '=https' --tlsv1.2 -fsSL https://opencode.ai/v2/install | bash`) and
   herdr (`brew install herdr`), then `herdr integration install opencode`.
   bun (`brew install oven-sh/bun/bun`) installs the opencode plugin
   dependencies; run `cd ~/.config/opencode && bun install` (or let `install.sh`
   do it) so the local plugins load.
8. Load `source $HOME/Projects/dotfiles/init.zsh` to .zshrc

`install.sh` automates steps 4-8 and links the repo-owned `~/.config` trees. It
detects the login shell (`$SHELL`) and appends the matching shim — `init.zsh`
for zsh, `init.bash` for bash:

```
bash ~/Projects/dotfiles/install.sh --dry-run   # preview, changes nothing
bash ~/Projects/dotfiles/install.sh             # apply
```

## Shell config

One config tree, two shells. `shell/shared/*.sh` holds everything that works in
both bash and zsh (aliases, functions, git helpers, AI helpers, secrets). At
the bottom of each file, `[[ -n "${ZSH_VERSION:-}" ]]` / `[[ -n
"${BASH_VERSION:-}" ]]` guards handle the few genuinely shell-specific lines.
`shell/mac/` and `shell/linux/` are OS splits; `shell/zsh/` holds zsh-only
extras (vi mode keys, zsh completions) that are skipped under bash.

```
shell/init.bash   # sourced from ~/.bashrc via ./init.bash
shell/init.zsh    # sourced from ~/.zshrc via ./init.zsh
```

Secrets live in `shell/shared/secrets.sh` (gitignored). `install.sh` creates it
from the tracked `shell/shared/secrets.example`; fill it in locally and keep it
mode `0600`.

## Linux (Omarchy / Arch)

Omarchy runs bash as the login shell; the config loads from `~/.bashrc` and
does not need zsh at all.

1. Clone the repo to `~/Projects/dotfiles` (same path as macOS — the rc shim
   hardcodes it).
2. Install packages:

   ```
   omarchy-pkg-add neovim jq
   mise use -g go@latest
   ```

   `go` is needed to build the herdr plugins; Omarchy ships `mise`, so it
   manages Go rather than a system package.

3. Install herdr:

   ```
   curl --proto '=https' --tlsv1.2 -fsSL https://herdr.dev/install.sh | sh
   ```

4. Install opencode v2. **Not** via mise: the mise/aqua registry only tracks the
   v1 zip releases. Use the AUR package (native `/usr/bin/opencode`) or the curl
   installer:
   ```
   yay -S opencode-beta
   # or
   curl --proto '=https' --tlsv1.2 -fsSL https://opencode.ai/v2/install | bash
   ```
   If v1 was mise-managed, remove it so the v2 binary wins: `mise uninstall opencode`.
5. Run the installer:

   ```
   bash ~/Projects/dotfiles/install.sh
   ```

   It moves any existing `~/.config/{opencode,herdr,nvim}` aside to
   `*.pre-dotfiles-YYYYmmdd-HHMMSS` and creates symlinks into this repo.
6. Install herdr plugins and the opencode integration:

   ```
   herdr plugin install crierr/herdr-arrange
   herdr plugin install abrose/herdr-numbered-workspaces
   herdr integration install opencode
   ```

7. Fill `shell/shared/secrets.sh` with machine-local values. `install.sh`
   creates it from `secrets.example` and keeps it gitignored and mode `0600`.

8. Reload the shared-server unit after the repo slice lands:

   ```
   systemctl --user daemon-reload
   systemctl --user restart opencode-server.service
   ```

9. Nvim: this repo's config replaces `omarchy-nvim`. After `omarchy reinstall
   configs` or `omarchy-nvim-refresh`, Omarchy may move the symlink aside;
   re-run `install.sh` to restore it.

10. Mailpit (local email catcher, used by OpenCodeHub in dev), from the AUR:

   ```
   yay -S mailpit-bin
   systemctl --user enable --now mailpit.service
   ```

   The repo ships `omarchy/systemd/mailpit.service`; `install.sh` links it.
   It binds loopback only (`127.0.0.1:8025` UI/API, `127.0.0.1:1025` SMTP) and
   keeps no database, so captured mail is dropped on restart. The AUR package
   also installs a system-scope `/usr/lib/systemd/system/mailpit.service` that
   binds `0.0.0.0`; leave it disabled.

11. ntfy (self-hosted, tailnet only), from the AUR:

   Install `ntfysh-bin` (the binary is `/usr/bin/ntfy`). Do **not** install the
   AUR package named `ntfy` — that is a different project (dschep/ntfy).

   ```
   yay -S ntfysh-bin
   systemctl --user disable --now ntfy-client.service  # preset-enabled, no config
   systemctl --user enable --now ntfy.service
   source ~/.bashrc   # shell/linux/ntfy.sh exports NTFY_AUTH_FILE for the CLI
   ntfy user add afif
   ntfy access afif afif-opencode rw
   ntfy token add afif    # -> OPENCODE_NTFY_TOKEN in shell/shared/opencode.env
   ```

   The server must start once before `ntfy user add`; that first start creates
   `~/.local/share/ntfy/{user.db,cache.db}`. Until then the CLI errors with
   `option database-url or auth-file not set`.

   The repo ships `omarchy/systemd/ntfy.service` and `config/ntfy/server.yml`;
   `install.sh` links the unit and exposes it with
   `tailscale serve --bg --http=15002 http://127.0.0.1:15002`. It binds loopback
   only and requires auth for every topic. Set in `shell/shared/opencode.env`:

   ```
   OPENCODE_NTFY_TOPIC=afif-opencode
   OPENCODE_NTFY_SERVER=http://<this-host>:15002
   OPENCODE_NTFY_TOKEN=<token from `ntfy token add`>
   OPENCODE_NTFY_URL=http://<this-machine>.<tailnet>.ts.net:15001
   ```

   `OPENCODE_NTFY_URL` is the click-through target, set per machine: it must be
   reachable from whatever taps the notification (the phone). Use this machine's
   tailnet MagicDNS URL, never another machine's. Unset => notifications carry
   no click action.

   Leaving `OPENCODE_NTFY_SERVER` unset falls back to the public `https://ntfy.sh`.

## How it is wired

| Piece | Wiring |
| --- | --- |
| `~/.config/opencode` | symlink to `$DOTFILES/config/opencode` |
| `~/.config/herdr` | symlink to `$DOTFILES/config/herdr` |
| `~/.config/nvim` | symlink to `$DOTFILES/config/nvim` |
| `~/.agents/skills` | symlink to `$DOTFILES/agents/skills` (shared global skill store, managed by `npx skills add -g`; writes land in the repo) |
| `~/.agents/.skill-lock.json` | symlink to `$DOTFILES/agents/.skill-lock.json` |
| shell | `shell/{shared,mac,linux,zsh}/`; login shell's rc (`~/.zshrc` or `~/.bashrc`) gains `# dotfiles` + `source "$HOME/Projects/dotfiles/init.{zsh,bash}"` |
| `bin/` | cross-platform scripts (`transcribe-youtube`) symlinked into `~/.local/bin` by `install.sh` on Linux and macOS |
| secrets | `shell/shared/secrets.sh` is gitignored; `install.sh` copies it from the tracked `shell/shared/secrets.example` and sets mode `0600` |
| herdr plugins | not in the repo; reinstall with the `herdr plugin install` commands above |
| opencode plugin deps | `config/opencode/package.json` is tracked; `node_modules` is not. Run `bun install` in `~/.config/opencode` after a fresh clone or config-tree move; `install.sh` does it when needed |
| nvim under Omarchy | repo config replaces `omarchy-nvim`; re-link after Omarchy updates |
| mailpit | `yay -S mailpit-bin`; `omarchy/systemd/mailpit.service` linked to `~/.config/systemd/user/`, enabled manually with `systemctl --user enable --now mailpit.service` |
| ntfy | `yay -S ntfysh-bin` (binary `/usr/bin/ntfy`; AUR `ntfy` is a different project); `omarchy/systemd/ntfy.service` + `config/ntfy/server.yml`; loopback `:15002` exposed with `tailscale serve --bg --http=15002`; auth required |
| shared server | the managed background service owns `0.0.0.0:15001` on both platforms; `install.sh` provisions port and hostname in `~/.config/opencode/service.json`. Tailnet clients reach `http://<host>:15001` directly, no serve (`install.sh` removes any stale mapping for 15001) |
| hop | `shell/shared/hop.sh`, auto-sourced on both platforms; `hop push`/`hop pull` over the tailnet. Mac->g4 rides Tailscale SSH identity; g4->Mac rides macOS Remote Login with `~/.ssh/id_ed25519` (`ssh-copy-id afifs-macbook-pro` once) |

## OpenCode v2

`~/.config/opencode/opencode.json` is native V2 (`permissions`, `agents`,
`mcp.servers`). The TUI config lives in `cli.json` (V2 replaced `tui.json`).
Platform-specific permission rules are merged into the one file; the old
`OPENCODE_CONFIG` split (`opencode.mac.json` / `opencode.linux.json`) is gone.
Omarchy-only MCP servers are injected by a Linux-gated plugin in
`config/opencode/plugins/cua-driver.ts`, so the shared `opencode.json` stays
Mac-clean and no platform-specific config file is needed.

The shared server on port 15001 is OpenCode's managed background service.
`install.sh` provisions its port (`15001`) and hostname (`0.0.0.0`) in
`~/.config/opencode/service.json`; `opencode serve --service` reads both. Each
host generates its own service password there. Clients (`oc`) discover the
registered service and start it on demand, so there is no `--server` flag and no
shared `OPENCODE_PASSWORD`.

`install.sh` also compares what is *running* to what is provisioned. Correct
config is not enough: systemd serves a cached copy of the unit until
`daemon-reload` runs, so a restart alone can relaunch the old argv, and an old
explicit `serve --port 15001` keeps the port. When `opencode service status`
reports anything other than `:15001`, the installer reloads and restarts the
service on Linux, or restarts the managed service on macOS.

Both platforms bind the server to `0.0.0.0`: the systemd unit on Linux, the
managed service on macOS. Tailnet clients reach `http://<host>:15001` directly,
so `opencode pair` links work as printed. `install.sh` removes any old
`tailscale serve` mapping for 15001; it would contend with the bind for the
node's port. HTTPS certs are only issued on `443`/`8443`/`10000`, and tailnet
traffic is WireGuard-encrypted, so plain HTTP on 15001 is fine. A `0.0.0.0`
bind is also reachable from the LAN; the service password gates it.

Pair a phone or browser with `opencode pair`: it mints a one-time link and QR
for the reachable URLs (`http://<host>:15001/auth/connect/<code>`, plus LAN and
loopback). Links die in 5 minutes and work once; the key the app receives lasts
about 30 days. The 15001 server must be running: the systemd unit on Linux, the
managed service on macOS (`oc` starts it on demand).

If OpenCode v2 is installed after `install.sh`, provision the service once per
machine (or re-run `install.sh`):

```sh
opencode service set port 15001
opencode service set hostname 0.0.0.0
```

On a machine upgrading from the old explicit server, the installer restarts the
unit and that old process dies with it. A foreign listener can still hold 15001;
`install.sh` warns when it does, and the fix is to stop it once:

```sh
pkill -f 'serve --port 15001'
```

`herdr integration install opencode` writes files into `~/.config/opencode`
(`plugins/`, `herdr-opencode/`, `cli.json` entry); those are gitignored. Reinstall
it after a fresh clone.

The local plugins under `config/opencode/plugins/` import bare packages at
runtime (`@opencode/plugin`, `@opencode-ai/plugin`, `opencode-tasks`). Those are
declared in the tracked `config/opencode/package.json`, but `node_modules` is
gitignored, so each machine must run `bun install` in `~/.config/opencode` once.
Without it, `history-search.ts` and `opencode-tasks-v2.ts` fail to load with
`Cannot find package '@opencode/plugin'` and their tools never register.
`install.sh` runs it automatically when `package.json` is newer than
`node_modules`. After installing, restart the shared server (`oc --restart` on
macOS, `systemctl --user restart opencode-server.service` on Linux).

## hop (file transfers g4 <-> Mac)

`shell/shared/hop.sh` defines `hop`; `shell/shared/*.sh` auto-sources on both
platforms, so the same command exists on g4 and the Mac:

```
hop push <src> [dst]   # send to the other machine
hop pull <src> [dst]   # fetch from the other machine
```

- `~/x` means "x under the home directory of whichever machine holds the
  file" (g4 `/home/afifsohaili`, macOS `/Users/afifsohaili`); absolute paths
  stay literal.
- Without `dst` the copy lands at the same path it came from; with `dst` it
  renames or moves. Directories copy recursively.
- The peer is picked by OS (Linux -> `afifs-macbook-pro`, Darwin ->
  `afifsohailig4`), overridable with `HOP_HOST`.

Auth differs per direction, by design:

| Direction | Transport | Credential |
| --- | --- | --- |
| Mac -> g4 | Tailscale SSH | tailnet identity, no keys |
| g4 -> Mac | macOS Remote Login (OpenSSH) | `~/.ssh/id_ed25519`, installed once with `ssh-copy-id afifs-macbook-pro` |

g4 advertises Tailscale SSH (`tailscale set --ssh`) and the tailnet ACL `ssh`
rule is `accept` for own devices, so any tailnet client can `ssh afifsohailig4`
without keys. The Mac cannot serve Tailscale SSH: the server component exists
only on Linux and the Homebrew `tailscaled` variant, not the macOS GUI app.
rsync interops both ways (GNU rsync on g4, Apple `openrsync` on the Mac);
verified with files and directories in both directions.
