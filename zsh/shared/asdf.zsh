if [[ -d "${ASDF_DATA_DIR:-$HOME/.asdf}" ]]; then
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

  fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
  autoload -Uz compinit && compinit

  [[ -f "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh" ]] && . "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh"
fi
