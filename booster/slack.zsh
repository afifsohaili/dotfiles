#!/bin/bash

alias current_branch='git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3'

function capistrano_app_name {
  local app_name
  app_name=$(pwd | rev | cut -d"/" -f 1 | rev)
  if [ $app_name = "cas_server" ]; then
    echo "cas" # other apps follow the booster_"folder_name" convention
  else
    echo $app_name
  fi
}

function containsElement() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && echo 0 && return; done
  echo 1
}

function slack {
  slack_channels=(
    "booster-notifications" "booster-staging-train" "klfunroom"
  )
  if [ `containsElement "$1" "${slack_channels[@]}"` = 0 ]; then
    echo $2 | slackcat -c $1 -p
  else
    echo $2 | slackcat -u $1 -p
  fi
}

function staging_queue {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  slack cibot "train booster_$app""_staging add $current_branch"
}

function production_queue {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  slack cibot "train booster_$app"" add $current_branch"
}

function staging_verify {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  slack "booster-notifications" "cibot train booster_$app""staging verify"
}

function production_verify {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  slack "booster-notifications" "cibot train booster_$app"" verify"
}
