if command -v starship >/dev/null 2>&1; then
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$(starship init zsh)"
  else
    eval "$(starship init bash)"
  fi
fi
