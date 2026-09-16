export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
autoload -Uz compinit && compinit

. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh
