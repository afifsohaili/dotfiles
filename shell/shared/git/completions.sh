# ga/gd are functions, not aliases (see shell/shared/aliases.sh), so bash-completion
# does not bind git's completion to them. Register the git subcommand handlers.
if [[ -n "${BASH_VERSION:-}" ]]; then
  if ! declare -F __git_complete >/dev/null 2>&1 && declare -F _completion_loader >/dev/null 2>&1; then
    _completion_loader git
  fi
  if declare -F __git_complete >/dev/null 2>&1; then
    __git_complete ga _git_add
    __git_complete gd _git_diff
  fi
fi
