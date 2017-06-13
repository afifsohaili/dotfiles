function booster_deploy() {
  [ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm";

  branch=`current_branch`;
  app=pwd | rev | cut -d"/" -f 1 | rev;
  capistrano_app=$app | cut -d"_" -f 1;

  cd /Users/afifsohaili/Booster/autotomy;

  eval "cap apps:booster_$capistrano_app"":staging deploy:clear_remote_cache";
  if [ "$branch" = "master" ]; then
    eval "cap apps:booster_$capistrano_app"":staging deploy";
  else
    eval "BRANCH=$branch cap apps:booster_$capistrano_app"":staging deploy";
  fi
  cd "/Users/afifsohaili/Booster/$capistrano_app";
}

