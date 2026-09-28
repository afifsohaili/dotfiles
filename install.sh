#!/usr/bin/env bash
# Dotfiles installer: links this repo into $HOME and wires the login shell's rc.
# Re-runnable. Use --dry-run to preview every action without touching anything.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      printf 'Usage: %s [--dry-run]\n' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

HERDR_INSTALL_URL="https://herdr.dev/install.sh"
OPENCODE_DOWNLOAD_URL="https://opencode.ai/download"
SECRETS_PATH="shell/shared/secrets.sh"

# Which rc file gets the shim. The login shell decides; overridable for testing
# with DOTFILES_SHELL_RC=~/.some-rc or DOTFILES_SKIP_SHELL_RC=1.
LOGIN_SHELL="$(basename "${SHELL:-/bin/bash}")"
case "$LOGIN_SHELL" in
  zsh) INIT_FILE="init.zsh"; DEFAULT_RC="$HOME/.zshrc" ;;
  *)   INIT_FILE="init.bash"; DEFAULT_RC="$HOME/.bashrc" ;;
esac
SHELL_RC="${DOTFILES_SHELL_RC:-$DEFAULT_RC}"
SHIM_LINE="source \"\$HOME/Projects/dotfiles/$INIT_FILE\""

say() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run]'
  else
    printf '+'
  fi
  printf ' %q' "$@"
  printf '\n'
  if [ "$DRY_RUN" -ne 1 ]; then
    "$@"
  fi
}

append_lines() {
  local file="$1"
  shift
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] append to %s:\n' "$file"
  else
    printf '\n' >> "$file"
    printf '%s\n' "$@" >> "$file"
    printf 'append to %s:\n' "$file"
  fi
  printf '  %s\n' "$@"
}

say "dotfiles: $DOTFILES"
if [ "$DRY_RUN" -eq 1 ]; then
  say "dry-run: no changes will be made"
fi

# 1. ~/.config symlinks for repo-owned config trees.
if [ ! -d "$HOME/.config" ]; then
  run mkdir -p "$HOME/.config"
fi

for name in opencode herdr nvim; do
  src="$DOTFILES/.config/$name"
  dest="$HOME/.config/$name"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    say "already linked: $dest -> $src"
    continue
  fi

  # A pre-existing symlink (possibly from a different path, possibly with a
  # trailing slash) is fine to relink, but back it up like a real file so the
  # old target can be restored. Only the exact match above is left alone.
  if [ ! -e "$src" ]; then
    say "warn: $src does not exist yet; the link will dangle until that repo slice lands" >&2
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
    run mv "$dest" "$backup"
  fi

  run ln -s "$src" "$dest"
done

# 2. Linux/Omarchy machine glue: omarchy/bin -> ~/.local/bin, and the systemd
#    units -> ~/.config/systemd/user. Also restores links that
#    `omarchy reinstall configs` may have moved aside.
link_files() {
  local srcdir="$1" destdir="$2" name src dest backup
  [ -d "$srcdir" ] || return 0
  if [ ! -d "$destdir" ]; then
    run mkdir -p "$destdir"
  fi
  for src in "$srcdir"/*; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    dest="$destdir/$name"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      say "already linked: $dest -> $src"
      continue
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
      backup="$dest.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
      run mv "$dest" "$backup"
    fi

    run ln -s "$src" "$dest"
  done
}

if [ "$(uname -s)" = "Linux" ]; then
  link_files "$DOTFILES/omarchy/bin" "$HOME/.local/bin"
  link_files "$DOTFILES/omarchy/systemd" "$HOME/.config/systemd/user"
  run systemctl --user daemon-reload
else
  say "machine glue: skipped (not Linux)"
fi

# 3. Login-shell rc shim.
if [ "${DOTFILES_SKIP_SHELL_RC:-0}" = "1" ]; then
  say "shell rc: skipped (DOTFILES_SKIP_SHELL_RC=1)"
elif [ -f "$SHELL_RC" ]; then
  if grep -Fq -- "$SHIM_LINE" "$SHELL_RC" || grep -Fq -- 'source $HOME/Projects/dotfiles/init.zsh' "$SHELL_RC"; then
    say "already present: $SHIM_LINE (in $SHELL_RC)"
  else
    append_lines "$SHELL_RC" "# dotfiles" "$SHIM_LINE"
  fi
else
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] create %s with:\n' "$SHELL_RC"
  else
    printf '%s\n' "# dotfiles" "$SHIM_LINE" > "$SHELL_RC"
    printf 'create %s with:\n' "$SHELL_RC"
  fi
  printf '  %s\n' "# dotfiles" "$SHIM_LINE"
fi

# 4. Keep machine-local secrets out of git status once they have local edits.
if GIT_OPTIONAL_LOCKS=0 git -C "$DOTFILES" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if GIT_OPTIONAL_LOCKS=0 git -C "$DOTFILES" diff --quiet -- "$SECRETS_PATH"; then
    say "skip-worktree: no local changes in $SECRETS_PATH, nothing to do"
  else
    run git -C "$DOTFILES" update-index --skip-worktree -- "$SECRETS_PATH"
  fi
else
  say "skip-worktree: not a git repo, skipping"
fi

# 5. Next steps, per OS.
say ""
say "== Next steps =="
case "$(uname -s)" in
  Darwin)
    say "macOS:"
    say "  - Tools (herdr, opencode, neovim) come from Homebrew:"
    say "      brew bundle install --file \"$DOTFILES/Brewfile\""
    say "  - Reload your shell: source ~/.zshrc"
    ;;
  Linux)
    say "Linux / Omarchy:"
    say "  - Packages (neovim, jq; opencode comes next):"
    say "      omarchy-pkg-add neovim jq"
    say "  - Go via mise (mise ships with Omarchy):"
    say "      mise use -g go@latest"
    say "  - herdr:"
    say "      curl -fsSL $HERDR_INSTALL_URL | sh"
    say "  - opencode, official installer or AUR:"
    say "      $OPENCODE_DOWNLOAD_URL"
    say "  - herdr plugins and integration:"
    say "      herdr plugin install crierr/herdr-arrange"
    say "      herdr plugin install abrose/herdr-numbered-workspaces"
    say "      herdr integration install opencode"
    say "  - Shell config loads from ~/.bashrc (no zsh needed)."
    say "  - Fill shell/shared/secrets.sh, then re-run install.sh (or run"
    say "      git update-index --skip-worktree shell/shared/secrets.sh)."
    say "  - After 'omarchy reinstall configs' or 'omarchy-nvim-refresh', symlinks may be"
    say "    moved aside. Re-run install.sh to restore them."
    ;;
  *)
    say "Unknown OS ($(uname -s)): set up tools manually."
    ;;
esac

exit 0
