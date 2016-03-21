# Makes git auto completion faster favouring for local completions
__git_files () {
    _wanted files expl 'local files' _files
}

alias css_files_changed="git diff --name-status master | grep \"^[A|M].*css\" | cut -f2 -d$'\t'"
alias files_changed="git diff --name-status master | grep \"^[A|M]\" | cut -f2 -d$'\t'"

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

alias gpr="hub pull-request -o"
