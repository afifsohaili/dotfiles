if command -v "rbenv" &> /dev/null
then
  export PATH="$(brew --prefix rbenv):$PATH"
  eval "$(rbenv init -)"

  alias be="bundle exec"
fi
