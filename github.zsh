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
