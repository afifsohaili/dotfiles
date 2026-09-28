if [[ -n "${BASH_VERSION:-}" ]]; then
  export HISTFILE="$HOME/.bash_history"
else
  export HISTFILE="$HOME/.zsh_history"
fi
