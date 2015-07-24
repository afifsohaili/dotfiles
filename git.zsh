# Makes git auto completion faster favouring for local completions
__git_files () {
    _wanted files expl 'local files' _files
}

alias css_files_changed="git diff --name-status master | grep \"^[A|M].*css\" | cut -f2 -d$'\t'"
alias files_changed="git diff --name-status master | grep \"^[A|M]\" | cut -f2 -d$'\t'"

function komit {
  git add .
  git commit -m "$1"
  current_branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
  if [ "$current_branch" = "master" ];
  then
  else
    echo "\033[0;32mDo you want to push this to remote? (y/n)"
    read can_push
    if [ "$can_push" = "y" ]; then
      git push origin --quiet "$current_branch" &
    fi
  fi
}

function new_branch() {
  branch=$1

  if [ "$branch" = "" ]; then
    return
  fi

  git checkout -b $branch
  echo "\033[0;32mCreating branch $branch on remote repo..."
  git push origin -u --quiet $branch &
}
