create_github_pr () {
  # get the remote url and lowercase it
  local REMOTE=`git remote get-url --push origin | tr '[:upper:]' '[:lower:]'`
  # replace git@ with https://
  REMOTE=`echo $REMOTE | sed 's/git@/https:\/\//'`
  # replace :kaligo (lowercased) with /Kaligo
  REMOTE=`echo $REMOTE | sed 's/:kaligo\//\/Kaligo\//'`
  # remove .git
  REMOTE=`echo $REMOTE | sed 's/\.git//'`
  # open the pull request page
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  echo "Creating pull request at: $REMOTE/pull/new/$BRANCH_NAME"
  open $REMOTE/pull/new/$BRANCH_NAME
}

get_pr_number () {
  BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
  local PR_NUMBER=`gh pr list --json headRefName,number --jq "map(select(.headRefName == \"$BRANCH_NAME\")) | .[0].number"`
  local REMOTE=`git remote get-url --push origin | tr '[:upper:]' '[:lower:]' | sed 's/git@/https:\/\//;s/:kaligo\//\/Kaligo\//;s/\.git//'`
  echo "PR: $REMOTE/pull/$PR_NUMBER"
  local CURRENT_FOLDER=`pwd | sed 's/.*\///'`
  echo "Jenkins: https://jenkins.int.kaligo.com/blue/organizations/jenkins/Ascenda%2F$CURRENT_FOLDER/activity?branch=PR-$PR_NUMBER"
}

function open_on_github() {
  # allow passing the file name to open
  local FILE_NAME=$1
  # get the remote url and lowercase it
  local REMOTE=`git remote get-url --push origin | tr '[:upper:]' '[:lower:]'`
  # replace git@ with https://
  REMOTE=`echo $REMOTE | sed 's/git@/https:\/\//'`
  # replace :kaligo (lowercased) with /Kaligo
  REMOTE=`echo $REMOTE | sed 's/:kaligo\//\/Kaligo\//'`
  # remove .git
  REMOTE=`echo $REMOTE | sed 's/\.git//'`
  # open the github page
  if [ -n "$FILE_NAME" ]; then
    # if pushed to remote, get the current commit hash, otherwise get master ref
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      CURRENT_COMMIT=`git rev-parse HEAD`
      open $REMOTE/blob/$CURRENT_COMMIT/$FILE_NAME
    else
      CURRENT_COMMIT=`git rev-parse master`
      open $REMOTE/blob/$CURRENT_COMMIT/$FILE_NAME
    fi
  else
    open $REMOTE
  fi
}
