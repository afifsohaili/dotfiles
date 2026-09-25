# Load order: shared config, then OS-specific config, then completions last
# (after asdf.zsh has run compinit).
DOTFILES="$HOME/Projects/dotfiles"

for config_file in "$DOTFILES"/zsh/shared/*.zsh(N) "$DOTFILES"/zsh/shared/ai/*.zsh(N) "$DOTFILES"/zsh/shared/git/*.zsh(N); do
  source "$config_file"
done

case "$(uname -s)" in
  Darwin)
    for config_file in "$DOTFILES"/zsh/mac/**/*.zsh(N); do
      source "$config_file"
    done
    ;;
  Linux)
    for config_file in "$DOTFILES"/zsh/linux/**/*.zsh(N); do
      source "$config_file"
    done
    ;;
esac

for config_file in "$DOTFILES"/zsh/shared/completions/*.zsh(N); do
  source "$config_file"
done
