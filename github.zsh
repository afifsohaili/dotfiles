function create_github_pr() {
  local remote=`git remote get-url --push origin`
  remote=`echo $remote | sed -En "s/git@/https:\/\//p"`
  remote=`echo $remote | sed -En "s/:servicerocket/\/servicerocket/p"`
  remote=`echo $remote | sed -En "s/github.com-sr/github.com/p"`
  remote=`echo $remote | sed -En "s/\.git//p"`
  open "$remote/pull/new/`git rev-parse --abbrev-ref HEAD`"
}
