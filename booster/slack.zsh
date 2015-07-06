alias current_branch='git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3'

function app_name {
  pwd | rev | cut -d"/" -f 1 | rev
}

function staging_queue {
  current_branch=`current_branch`
  app=`app_name`
  slack cibot "train booster_$app""_staging add $current_branch"
}

function release_queue {
  current_branch=`current_branch`
  app=`app_name`
  slack cibot "train booster_$app"" add $current_branch"
}

function slack {
  echo $2 | slackcat -u $1 -p
}

function release_verify {
  current_branch=`current_branch`
  app=`app_name`
  slack cibot "train booster_$app"" verify"
}

function staging_verify {
  current_branch=`current_branch`
  app=`app_name`
  slack cibot "train booster_$app""staging verify"
}
