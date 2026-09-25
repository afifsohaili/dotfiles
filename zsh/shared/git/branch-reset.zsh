function branch_reset() {
  if [ -n "$1" ]; then
    git fetch && git reset --hard origin/$1
  else
    git fetch && git reset --hard origin/$(current_branch)
  fi
}
alias br=branch_reset
