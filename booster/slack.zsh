function staging_queue {
  current_branch=git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3 
  slack cibot "train booster_fulcrum_staging $current_branch"
}

function slack {
  echo $2 | slackcat -u $1 -p;
}
