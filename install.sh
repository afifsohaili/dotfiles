#!/usr/bin/env bash
# Dotfiles installer: links this repo into $HOME and wires ~/.zshrc.
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
SHIM_LINE='source "$HOME/Projects/dotfiles/init.zsh"'
SECRETS_PATH="zsh/shared/secrets.zsh"

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

  if [ ! -e "$src" ]; then
    say "warn: $src does not exist yet; the link will dangle until that repo slice lands" >&2
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$dest.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
    run mv "$dest" "$backup"
  fi

  run ln -s "$src" "$dest"
done

# 2. ~/.zshrc shim.
ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
  if grep -Fq -- "$SHIM_LINE" "$ZSHRC" || grep -Fq -- 'source $HOME/Projects/dotfiles/init.zsh' "$ZSHRC"; then
    say "already present: $SHIM_LINE (in $ZSHRC)"
  else
    append_lines "$ZSHRC" "# dotfiles" "$SHIM_LINE"
  fi
else
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] create %s with:\n' "$ZSHRC"
  else
    printf '%s\n' "# dotfiles" "$SHIM_LINE" > "$ZSHRC"
    printf 'create %s with:\n' "$ZSHRC"
  fi
  printf '  %s\n' "# dotfiles" "$SHIM_LINE"
fi

# 3. Keep machine-local secrets out of git status once they have local edits.
if GIT_OPTIONAL_LOCKS=0 git -C "$DOTFILES" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if GIT_OPTIONAL_LOCKS=0 git -C "$DOTFILES" diff --quiet -- "$SECRETS_PATH"; then
    say "skip-worktree: no local changes in $SECRETS_PATH, nothing to do"
  else
    run git -C "$DOTFILES" update-index --skip-worktree -- "$SECRETS_PATH"
  fi
else
  say "skip-worktree: not a git repo, skipping"
fi

# 4. Next steps, per OS.
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
    say "  - Package names below are unverified; check them against Omarchy/Arch repos first:"
    say "      omarchy-pkg-add zsh neovim go jq"
    say "  - herdr:"
    say "      curl -fsSL $HERDR_INSTALL_URL | sh"
    say "  - opencode, official installer or AUR:"
    say "      $OPENCODE_DOWNLOAD_URL"
    say "  - herdr plugins and integration:"
    say "      herdr plugin install crierr/herdr-arrange"
    say "      herdr plugin install abrose/herdr-numbered-workspaces"
    say "      herdr integration install opencode"
    say "  - Keep bash as the login shell; launch zsh in the terminal instead."
    say "  - Fill zsh/shared/secrets.zsh, then re-run install.sh (or run"
    say "      git update-index --skip-worktree zsh/shared/secrets.zsh)."
    say "  - After 'omarchy reinstall configs' or 'omarchy-nvim-refresh', symlinks may be"
    say "    moved aside. Re-run install.sh to restore them."
    ;;
  *)
    say "Unknown OS ($(uname -s)): set up tools manually."
    ;;
esac

exit 0
