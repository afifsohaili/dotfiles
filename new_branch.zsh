function new_branch() {
  branch=$1

  if [ "$branch" = "" ]; then
    return
  fi

  git checkout -b $branch
  git fetch
  git reset --hard origin/master
  echo "\033[0;32mCreating branch $branch on remote repo..."
  git push origin -u --quiet $branch &
}
alias nbr="new_branch"
