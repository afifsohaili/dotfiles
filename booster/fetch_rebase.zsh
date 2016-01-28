function fetch_rebase() {
  branch="origin/master"
  if [ -n "$1" ]; then
    branch="$1"
  fi
  git fetch && git rebase $branch
}

alias gfrb='fetch_rebase'
