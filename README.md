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

`install.sh` automates steps 4-7 and links the repo-owned `~/.config` trees:

```
bash ~/Projects/dotfiles/install.sh --dry-run   # preview, changes nothing
bash ~/Projects/dotfiles/install.sh             # apply
```

## Linux (Omarchy / Arch)

Omarchy assumes bash as the login shell. Keep it: launch zsh in the terminal
instead of changing the shell with `chsh`.

1. Clone the repo to `~/Projects/dotfiles` (same path as macOS — the `~/.zshrc`
   shim hardcodes it).
2. Install packages. **Package names below need a check against the Omarchy/Arch
   repos before running** (unverified):

   ```
   omarchy-pkg-add zsh neovim go jq
   ```

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

7. Fill `zsh/shared/secrets.zsh` with machine-local values, then re-run
   `install.sh` (or run `git update-index --skip-worktree
   zsh/shared/secrets.zsh`) so the edits stay out of `git status`.

8. Nvim: this repo's config replaces `omarchy-nvim`. After `omarchy reinstall
   configs` or `omarchy-nvim-refresh`, Omarchy may move the symlink aside;
   re-run `install.sh` to restore it.

## How it is wired

| Piece | Wiring |
| --- | --- |
| `~/.config/opencode` | symlink to `$DOTFILES/.config/opencode` |
| `~/.config/herdr` | symlink to `$DOTFILES/.config/herdr` |
| `~/.config/nvim` | symlink to `$DOTFILES/.config/nvim` |
| zsh | `zsh/{shared,mac,linux}/` split; `~/.zshrc` gains `# dotfiles` + `source "$HOME/Projects/dotfiles/init.zsh"` |
| secrets | template at `zsh/shared/secrets.zsh`; local edits marked with `git update-index --skip-worktree zsh/shared/secrets.zsh` |
| herdr plugins | not in the repo; reinstall with the `herdr plugin install` commands above |
| nvim under Omarchy | repo config replaces `omarchy-nvim`; re-link after Omarchy updates |
