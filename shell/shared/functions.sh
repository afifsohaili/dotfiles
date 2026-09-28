# Shared across bash and zsh. Keep POSIX + bash/zsh-common syntax only.
function title() { printf '\033]0;%s\007' "$1"; }

if [[ -n "${ZSH_VERSION:-}" ]]; then
  # zsh: no system title hook; set user@host? dir name on each prompt.
  # (bash gets titles from /etc/bash.bashrc on Omarchy and starship elsewhere.)
  precmd () { printf '\033]0; %s\007' "${PWD##*/}"; }
fi

# zsh: `reload` is defined in aliases.sh.

function awkcut() {
  awk '{print $'"$1"'}'
}
