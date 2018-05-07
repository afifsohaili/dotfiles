export HOME="/Users/afifsohaili"

function title() { echo -n -e "\033]0;$1\007" }
alias reload="source ~/.zshrc"
alias be='bundle exec'

precmd () { echo -ne "\033]0; ${PWD##*/}\007" }
