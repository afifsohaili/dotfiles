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

function staging_queue {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  description=$current_branch
  staging=$1
  if [ -n "$2" ]; then
    description="$2"
  fi
  if [ "$1" = "1" ]; then
    staging=" "
  fi
  slack chat send "train booster_$app""_staging$staging"" add $description" @cibot
}
alias sq="staging_queue"

function production_queue {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  description=$current_branch
  if [ -n "$1" ]; then
    description="$1"
  fi
  slack chat send "train booster_$app"" add $description" @cibot
}
alias pq="production_queue"

function staging_verify {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  description=$current_branch
  staging=$1
  if [ -n "$2" ]; then
    description="$2"
  fi
  if [ "$1" = "1" ]; then
    staging=" "
  fi
  slack chat send "cibot train booster_$app""_staging$staging"" verify $description" "#booster-staging-train"
}
alias sv="staging_verify"

function production_verify {
  current_branch=`current_branch`
  app=`capistrano_app_name`
  slack chat send "cibot train booster_$app"" verify" "#booster-notifications"
}
alias pv="production_verify"

function production_remind() {
  app=`capistrano_app_name`
  slack chat send "cibot train booster_$app" "#booster-notifications"
}
alias pr="production_remind"
