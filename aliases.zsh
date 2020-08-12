# Custom Git functions
alias gpso='git push origin'
alias gpf='git push --force'
alias gcpk='git cherry-pick'
alias gjr='git jira'
alias gjro='git jira -o'
alias grom='git rebase origin/master'
alias gfrs='git fetch && git reset --hard origin/master'
alias gpr="hub pull-request -o"
alias gfrb='git fetch --rebase'
alias gcane='git commit --amend --no-edit'

# General aliases
alias css_files_changed="git diff --name-status master | grep \"^[A|M].*css\" | cut -f2 -d$'\t'"
alias files_changed="git diff --name-status master | grep \"^[A|M]\" | cut -f2 -d$'\t'"

# Meteor specific
alias mts="npm start"
alias mtd="npm run deploy"

alias bsr="brew services restart"

# Yarn
alias ya="yarn add"
alias yr="yarn remove"
alias yad="yarn add -D"

alias reload='source ~/.zshrc'
alias vi='vim'
