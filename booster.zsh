alias booster="~/Booster"

function killrails {
  ps -ef | grep "p " | grep ruby | grep -v grep | awk '{print $2}' | xargs kill -9;
  ps -ef | grep rails | grep -v grep | awk '{print $2}' | xargs kill -9;
  ps -ef | grep rackup | grep -v grep | awk '{print $2}' | xargs kill -9;
  ps -ef | grep subcontract | grep -v grep | awk '{print $2}' | xargs kill -9;
}

function booster_merge {
  green="\033[0;32m"
  red="\033[0;31m"

  current_branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
  mergeable="Y"

  if [ "${current_branch}" = "master" ]; then
    echo -e $red"You cannot merge master to master"
  else
    git checkout --quiet master
    echo -e "Pulling latest master"
    git pull --rebase --quiet --prune origin master
    git checkout --quiet $current_branch

    echo -e "Rebasing $current_branch with latest master"

    if git rebase master | grep 'conflict' &> /dev/null; then
      git rebase --abort
      echo -e $red"There are merge conflicts with master"
    else
      git push --force-with-lease --quiet origin $current_branch

      number_of_commits=$(git log HEAD...master --pretty=oneline | wc -l)
      if [ "$number_of_commits" -gt 1 ]; then
        echo $red"You have multiple commit messages. It's advisable to squash all commits into just one."
        echo $red"Do you still want to continue merging? (Y/N)"
        read mergeable
      fi

      if [ "$mergeable" = "Y" ]; then
        echo -e $green"Succeeded. Merging..."
        git checkout --quiet master

        echo -e "Merging $current_branch to master"
        git merge --ff-only $current_branch

        echo -e $green"Merged. Pushing to master..."
        git push origin master

        echo -e $green"Cleaning up"
        git push origin --quiet :$current_branch # delete remote branch
        git branch -D --quiet $current_branch # delete local branch

        echo -e $green"\n$current_branch has been merged to master"
        echo -e $green"$current_branch has been deleted from remote repository"
        echo -e $green"$current_branch has been deleted from local repository\n"
      else
        echo $red"Merge aborted..."
      fi
    fi
  fi
}

function booster_pull() {
  green="\033[0;32m"
  red="\033[0;31m"
  purple="\033[0;35m"

  # allow changing gemsets when navigating between repo directories
  [ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

  # Path to Booster project folder
  booster_path=/Users/afifsohaili/Booster

  booster_apps=(
    admin autotomy backend donation user_service
    cas_server fulcrum dev_proxy styleguide
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
    git pull --rebase --prune --quiet origin master
    if git diff old_master master | grep 'Gemfile.lock' &> /dev/null; then
      echo $red"There are gem updates. Running bundle install in the background."
      bundle install >/dev/null 2>/dev/null &
    fi
    if git diff old_master master | grep 'db/migrate/' &> /dev/null; then
      echo $red"New migration(s) found. Running rake db:migrate in the background."
      bundle exec rake db:migrate >/dev/null 2>/dev/null &
    fi
    git branch -D --quiet old_master
  done

  cd "$booster_path/fulcrum"
}

function hound_check() {
  files=("$@")
  for file in "${files[@]}"
  do
    if [[ "$file" == *rb ]]; then
      rubocop -c .ruby-style.yml $file
    elif [[ "$file" == *css ]]; then
      scss-lint -c .scss-style.yml $file
    fi
  done
}

function booster_deploy() {
  [ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

  branch=`current_branch`
  app=$(pwd | rev | cut -d"/" -f 1 | rev)
  capistrano_app=$($app | cut -d"_" -f 1)

  cd /Users/afifsohaili/Booster/autotomy

  eval "cap apps:booster_$capistrano_app"":staging deploy:clear_remote_cache"
  if [ "$branch" = "master" ]; then
    eval "cap apps:booster_$capistrano_app"":staging deploy"
  else
    eval "BRANCH=$branch cap apps:booster_$capistrano_app"":staging deploy"
  fi
  cd "/Users/afifsohaili/Booster/$capistrano_app"
}

function booster_start {
  killrails
  cd ~/Booster/dev_proxy/
  echo -n -e "\033]0;rails_servers\007"
  ./bin/start
}
