alias booster="~/Booster"

function killrails {
  ps -ef | grep rails | grep -v grep | awk '{print $2}' | xargs kill -9;
  ps -ef | grep rackup | grep -v grep | awk '{print $2}' | xargs kill -9;
  ps -ef | grep subcontract | grep -v grep | awk '{print $2}' | xargs kill -9;
}

function killspring {
  ps -ef | grep "spring " | grep -v grep | awk '{print $2}' | xargs kill -9;
}

function killrspec {
  ps -ef | grep rspec | grep -v grep | awk '{print $2}' | xargs kill -9;
}

