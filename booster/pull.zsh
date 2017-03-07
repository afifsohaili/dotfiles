function booster_pull() {
  green="\033[0;32m"
  red="\033[0;31m"
  purple="\033[0;35m"

  # allow changing gemsets when navigating between repo directories
  [ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

  # Path to Booster project folder
  booster_path=/Users/afifsohaili/Booster

  booster_apps=(
    autotomy fulcrum integration_test
  )

  for app in "${booster_apps[@]}"
  do
    has_stash=false
    cd $booster_path"/"$app
    echo $green"\nCurrently in $app\n"$purple
    current_branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
    diff=$(git diff | awk "{print $1;}")
    if [ -n "$diff" ]; then
      echo $purple"Work in progress found. Saving..."
      git stash --quiet
      has_stash=true
    fi
    git checkout --quiet master
    git branch --quiet old_master
    git pull --rebase --prune --quiet
    if git diff old_master master | grep 'Gemfile.lock' &> /dev/null; then
      echo $red"There are gem updates. Running bundle install in the background."
      bundle install >/dev/null 2>/dev/null &
    fi
    if git diff old_master master | grep 'db/migrate/' &> /dev/null; then
      echo $red"New migration(s) found. Running rake db:migrate in the background."
      bundle exec rake db:migrate >/dev/null 2>/dev/null &
      bundle exec rake db:setup RAILS_ENV=test >/dev/null 2>/dev/null &
    fi
    git branch -D --quiet old_master
  done
  cd $booster_path"/integration_test"
  git checkout --quiet as-customized-script
  git rebase --quiet origin/master
  cd $booster_path"/fulcrum"
}

alias bp=booster_pull
