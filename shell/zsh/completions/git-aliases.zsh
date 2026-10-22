# ga/gd are functions, not aliases (see shell/shared/aliases.sh), so zsh has no
# completion spec for them and falls back to filenames. Bind git's spec instead.
if (( $+functions[compdef] )); then
  compdef _git ga=git-add
  compdef _git gd=git-diff
fi
