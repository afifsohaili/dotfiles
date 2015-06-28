export PATH="$PATH:$HOME/.composer/vendor/bin"
export PATH="$PATH:$(brew --prefix homebrew/php/php54)/bin"
export HOME="/Users/afifsohaili"
export CXX=g++-4.8
export CC=gcc-4.8
export gcc=gcc-4.8
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

function title() { echo -n -e "\033]0;$1\007" }
alias reload="source ~/.zshrc"
alias database_refresh="rake db:drop && rake db:create && rake db:migrate && rake db:seed"
alias be='bundle exec'

precmd () { echo -ne "\033]0; ${PWD##*/}\007" }
