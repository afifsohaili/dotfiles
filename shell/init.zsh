# Load order: shared config, then OS-specific config, then zsh-only extras
# (vi-mode keys, completions) last.
DOTFILES="$HOME/Projects/dotfiles"

for config_file in "$DOTFILES"/shell/shared/*.sh(N) "$DOTFILES"/shell/shared/ai/*.sh(N) "$DOTFILES"/shell/shared/git/*.sh(N); do
  source "$config_file"
done

case "$(uname -s)" in
  Darwin)
    for config_file in "$DOTFILES"/shell/mac/*.sh(N) "$DOTFILES"/shell/mac/ai/*.sh(N); do
      source "$config_file"
    done
    ;;
  Linux)
    for config_file in "$DOTFILES"/shell/linux/*.sh(N); do
      source "$config_file"
    done
    ;;
esac

for config_file in "$DOTFILES"/shell/zsh/*.zsh(N) "$DOTFILES"/shell/zsh/completions/*.zsh(N); do
  source "$config_file"
done
