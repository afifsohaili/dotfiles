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
OPENCODE_DOWNLOAD_URL="https://opencode.ai/v2"
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

  # Restart the shared server when its unit changed, so a new ExecStart (e.g.
  # the v2 binary resolution) takes effect without a manual step. Failure is
  # non-fatal: the machine may not have opencode installed yet.
  opencode_unit="$HOME/.config/systemd/user/opencode-server.service"
  if [ -e "$opencode_unit" ] && systemctl --user is-enabled opencode-server.service >/dev/null 2>&1; then
    run systemctl --user restart opencode-server.service 2>/dev/null || \
      say "warn: could not restart opencode-server.service (is opencode v2 installed?)"
  fi

  # pnpm global-install policy. pnpm v11 resolves bare imports from a hoisted
  # node_modules only; @pen.dev/cli imports css-tree without declaring it, so the
  # default isolated layout breaks `pen`. This file is read whenever a global
  # command runs from $PNPM_HOME. minimumReleaseAge is deliberately left alone:
  # the CLI needs its newest release, so upgrade it with
  # `pnpm add -g @pen.dev/cli@latest --config.minimumReleaseAge=0`.
  PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
  pnpm_global_dir="$PNPM_HOME/global/v11"
  pnpm_workspace="$pnpm_global_dir/pnpm-workspace.yaml"
  if [ -d "$pnpm_global_dir" ] && [ ! -e "$pnpm_workspace" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '[dry-run] write %s: nodeLinker: hoisted\n' "$pnpm_workspace"
    else
      printf 'nodeLinker: hoisted\n' > "$pnpm_workspace"
      say "wrote $pnpm_workspace"
    fi
  fi

  # Timers shipped with the repo are opt-in units, not services: enable the
  # ones we know about so the data they refresh stays current on a fresh box.
  for timer in omarchy-agent-usage-ollama.timer; do
    unit="$HOME/.config/systemd/user/$timer"
    [ -e "$unit" ] || continue
    run systemctl --user enable "$timer" 2>/dev/null || true
  done

  # Shell plugins (e.g. local.caffeinate) are directories, not single files.
  # Symlink each plugin dir into the Omarchy plugin path, then rescan so the
  # shell picks them up without a restart. The shell watches plugin code for
  # changes, so a rescan is enough.
  if [ -d "$DOTFILES/omarchy/plugins" ]; then
    plugins_dest="$HOME/.config/omarchy/plugins"
    plugins_linked=0
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '[dry-run] mkdir -p %q\n' "$plugins_dest"
    else
      mkdir -p "$plugins_dest"
    fi
    for src in "$DOTFILES/omarchy/plugins"/*/; do
      [ -d "$src" ] || continue
      src="${src%/}"
      name="$(basename "$src")"
      dest="$plugins_dest/$name"

      if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        say "already linked: $dest -> $src"
        continue
      fi

      if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup="$dest.pre-dotfiles-$(date +%Y%m%d-%H%M%S)"
        run mv "$dest" "$backup"
      fi

      run ln -s "$src" "$dest"
      plugins_linked=1
    done
    if [ "$plugins_linked" -eq 1 ] && [ "$DRY_RUN" -ne 1 ]; then
      # A new/changed plugin dir is picked up without a restart; enable it on
      # first install so the widget lands in the bar.
      run omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
    fi
  fi
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

# 4b. Shared opencode server password. V2 servers require one; the login shell
#     and the systemd unit both read this file, so a client can authenticate.
OPENCODE_ENV="$DOTFILES/shell/shared/opencode.env"
if grep -q '^OPENCODE_PASSWORD=' "$OPENCODE_ENV" 2>/dev/null; then
  say "opencode: OPENCODE_PASSWORD present in $OPENCODE_ENV"
elif [ "$DRY_RUN" -eq 1 ]; then
  printf '[dry-run] generate OPENCODE_PASSWORD in %s\n' "$OPENCODE_ENV"
else
  ( umask 077; printf 'OPENCODE_PASSWORD=%s\n' "$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')" >> "$OPENCODE_ENV" )
  say "opencode: generated OPENCODE_PASSWORD in $OPENCODE_ENV"
fi

# 5. Next steps, per OS.
say ""
say "== Next steps =="
case "$(uname -s)" in
  Darwin)
    say "macOS:"
    say "  - Tools (herdr, neovim) come from Homebrew:"
    say "      brew bundle install --file \"$DOTFILES/Brewfile\""
    say "  - opencode v2 (curl installer replaces the v1 ~/.opencode/bin binary):"
    say "      curl -fsSL https://opencode.ai/v2/install | bash"
    say "  - Reload your shell: source ~/.zshrc"
    ;;
  Linux)
    say "Linux / Omarchy:"
    say "  - Packages (neovim, jq, uv; uv runs the websearch MCP server):"
    say "      omarchy-pkg-add neovim jq uv"
    say "  - Go via mise (mise ships with Omarchy):"
    say "      mise use -g go@latest"
    say "  - herdr:"
    say "      curl -fsSL $HERDR_INSTALL_URL | sh"
    say "  - opencode v2. NOT via mise: the mise/aqua registry only tracks v1."
    say "    Either the AUR package (native, /usr/bin/opencode):"
    say "      paru -S opencode-beta"
    say "    or the curl installer (~/.opencode/bin/opencode):"
    say "      curl -fsSL https://opencode.ai/v2/install | bash"
    say "    If v1 was mise-managed, drop it so the v2 binary wins:"
    say "      mise uninstall opencode"
    say "  - herdr plugins and integration:"
    say "      herdr plugin install crierr/herdr-arrange"
    say "      herdr plugin install abrose/herdr-numbered-workspaces"
    say "      herdr integration install opencode"
    say "  - Reload systemd units after re-running this installer:"
    say "      systemctl --user daemon-reload"
    say "      systemctl --user restart opencode-server.service"
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
