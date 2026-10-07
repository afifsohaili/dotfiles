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
7. Install opencode v2 (`curl -fsSL https://opencode.ai/v2/install | bash`) and
   herdr (`brew install herdr`), then `herdr integration install opencode`.
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

Secrets live in `shell/shared/secrets.sh` (template, tracked; fill locally).

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
   curl -fsSL https://herdr.dev/install.sh | sh
   ```

4. Install opencode v2. **Not** via mise: the mise/aqua registry only tracks the
   v1 zip releases. Use the AUR package (native `/usr/bin/opencode`) or the curl
   installer:
   ```
   paru -S opencode-beta
   # or
   curl -fsSL https://opencode.ai/v2/install | bash
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

7. Fill `shell/shared/secrets.sh` with machine-local values, then re-run
   `install.sh` (or run `git update-index --skip-worktree
   shell/shared/secrets.sh`) so the edits stay out of `git status`.

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

## How it is wired

| Piece | Wiring |
| --- | --- |
| `~/.config/opencode` | symlink to `$DOTFILES/config/opencode` |
| `~/.config/herdr` | symlink to `$DOTFILES/config/herdr` |
| `~/.config/nvim` | symlink to `$DOTFILES/config/nvim` |
| shell | `shell/{shared,mac,linux,zsh}/`; login shell's rc (`~/.zshrc` or `~/.bashrc`) gains `# dotfiles` + `source "$HOME/Projects/dotfiles/init.{zsh,bash}"` |
| secrets | template at `shell/shared/secrets.sh`; local edits marked with `git update-index --skip-worktree shell/shared/secrets.sh` |
| herdr plugins | not in the repo; reinstall with the `herdr plugin install` commands above |
| nvim under Omarchy | repo config replaces `omarchy-nvim`; re-link after Omarchy updates |
| mailpit | `yay -S mailpit-bin`; `omarchy/systemd/mailpit.service` linked to `~/.config/systemd/user/`, enabled manually with `systemctl --user enable --now mailpit.service` |

## OpenCode v2

`~/.config/opencode/opencode.json` is native V2 (`permissions`, `agents`,
`mcp.servers`). The TUI config lives in `cli.json` (V2 replaced `tui.json`).
Platform-specific permission rules are merged into the one file; the old
`OPENCODE_CONFIG` split (`opencode.mac.json` / `opencode.linux.json`) is gone.

The shared server on port 15001 needs a password in V2. `shell/shared/opencode.sh`
generates `OPENCODE_PASSWORD` into the gitignored `shell/shared/opencode.env`;
the systemd unit reads the same file. Clients (`oc`) connect with
`opencode --server http://127.0.0.1:15001`.

`herdr integration install opencode` writes files into `~/.config/opencode`
(`plugins/`, `herdr-opencode/`, `cli.json` entry); those are gitignored. Reinstall
it after a fresh clone.
