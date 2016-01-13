function booster_start {
  killrails;
  cd ~/Booster/fulcrum/;
  echo -n -e "\033]0;rails_servers\007";
  bundle exec spring rails s -p 3000;
}

alias bs=booster_start
