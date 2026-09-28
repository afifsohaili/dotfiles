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
7. Load `source $HOME/Projects/dotfiles/init.zsh` to .zshrc

`install.sh` automates steps 4-7 and links the repo-owned `~/.config` trees. It
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

4. Install opencode with its official installer, or from the AUR. See
   <https://opencode.ai/download>.
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

8. Nvim: this repo's config replaces `omarchy-nvim`. After `omarchy reinstall
   configs` or `omarchy-nvim-refresh`, Omarchy may move the symlink aside;
   re-run `install.sh` to restore it.

## How it is wired

| Piece | Wiring |
| --- | --- |
| `~/.config/opencode` | symlink to `$DOTFILES/.config/opencode` |
| `~/.config/herdr` | symlink to `$DOTFILES/.config/herdr` |
| `~/.config/nvim` | symlink to `$DOTFILES/.config/nvim` |
| shell | `shell/{shared,mac,linux,zsh}/`; login shell's rc (`~/.zshrc` or `~/.bashrc`) gains `# dotfiles` + `source "$HOME/Projects/dotfiles/init.{zsh,bash}"` |
| secrets | template at `shell/shared/secrets.sh`; local edits marked with `git update-index --skip-worktree shell/shared/secrets.sh` |
| herdr plugins | not in the repo; reinstall with the `herdr plugin install` commands above |
| nvim under Omarchy | repo config replaces `omarchy-nvim`; re-link after Omarchy updates |
