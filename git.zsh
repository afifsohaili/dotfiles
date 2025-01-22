export PATH="$PATH:$HOME/Projects/dotfiles/git/bin"
export PATH="$PATH:$HOME/Projects/dotfiles/bin"
zstyle ':completion:*:*' ignored-patterns '*ORIG_HEAD'

alias cb="git_current_branch"
alias griom="git rebase -i origin/master"

export EDITOR='nvim'
export VISUAL='nvim'

function git_recent_branches() {
  # get last n results, default to 20
  local result_count=${1:-20}
  git reflog | grep "checkout:" | head -n $result_count | grep -o "to [^']*" | sed 's/to //' | awk '!seen[$0]++'
}
