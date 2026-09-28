# Load order: shared config, then OS-specific config.
# Requires bash >= 4 (arrays, [[ ]]). Omarchy ships bash 5.
DOTFILES="${DOTFILES:-$HOME/Projects/dotfiles}"

for config_file in "$DOTFILES"/shell/shared/*.sh "$DOTFILES"/shell/shared/ai/*.sh "$DOTFILES"/shell/shared/git/*.sh; do
  [ -r "$config_file" ] && source "$config_file"
done

case "$(uname -s)" in
  Darwin)
    for config_file in "$DOTFILES"/shell/mac/*.sh "$DOTFILES"/shell/mac/ai/*.sh; do
      [ -r "$config_file" ] && source "$config_file"
    done
    ;;
  Linux)
    for config_file in "$DOTFILES"/shell/linux/*.sh; do
      [ -r "$config_file" ] && source "$config_file"
    done
    ;;
esac
