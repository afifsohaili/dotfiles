function title() { echo -n -e "\033]0;$1\007" }
alias reload="source ~/.zshrc"

precmd () { echo -ne "\033]0; ${PWD##*/}\007" }

function awkcut() {
  awk '{print $'"$1"'}'
}
