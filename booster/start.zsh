function booster_start {
  killrails;
  cd ~/Booster/dev_proxy/;
  echo -n -e "\033]0;rails_servers\007";
  ./bin/start;
}
