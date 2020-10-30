# From YADR
alias psa="ps aux"
alias ll='ls -alGh'
alias ls='ls -Gh'

# Git Aliases
alias gs='git status'
alias gps='git push'
alias gst='git stash'
alias gcm='git commit -m'
alias gco='git checkout'
alias ga='git add -A'
alias gr='git rebase'
alias gri='git rebase -i'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gl='git log --graph --date=short'
alias gf='git fetch'
alias gfp='git fetch --prune'
alias gd='git diff'
alias gb='git branch -v'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias grs='git reset'
alias grsh='git reset --hard'
alias gt='git t'
alias gbg='git bisect good'
alias gbb='git bisect bad'

# Common shell functions
alias less='less -r'
alias tf='tail -f'
alias l='less'
alias lh='ls -alt | head' # see the last modified files
alias screen='TERM=screen screen'

alias k9='kill -9'

# Homebrew
alias brewu='brew update && brew upgrade && brew cleanup && brew doctor'

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
alias vi="nvim"
alias vim="nvim"
