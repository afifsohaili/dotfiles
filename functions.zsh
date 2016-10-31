export PATH="$PATH:$HOME/.composer/vendor/bin"
export PATH="$PATH:$(brew --prefix homebrew/php/php54)/bin"
export HOME="/Users/afifsohaili"

function title() { echo -n -e "\033]0;$1\007" }
alias reload="source ~/.zshrc"
alias be='bundle exec'

precmd () { echo -ne "\033]0; ${PWD##*/}\007" }
