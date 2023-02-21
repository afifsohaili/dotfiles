if command -v "rbenv" &> /dev/null
then
  export PATH="$(brew --prefix rbenv):$PATH"
  eval "$(rbenv init -)"
fi

if command -v "bundle" &> /dev/null
then
  alias be="bundle exec"
fi
