function booster_merge {
  green="\033[0;32m"
  red="\033[0;31m"

  current_branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
  mergeable="Y"

  if [ "${current_branch}" = "master" ]; then
    echo -e $red"You cannot merge master to master"
  else
    git checkout --quiet master
    echo -e "Pulling latest master"
    git pull --rebase --quiet --prune origin master
    git checkout --quiet $current_branch

    echo -e "Rebasing $current_branch with latest master"

    if git rebase master | grep 'conflict' &> /dev/null; then
      git rebase --abort
      echo -e $red"There are merge conflicts with master"
    else
      git push --force-with-lease --quiet origin $current_branch

      number_of_commits=$(git log HEAD...master --pretty=oneline | wc -l)
      if [ "$number_of_commits" -gt 1 ]; then
        echo $red"You have multiple commit messages. It's advisable to squash all commits into just one."
        echo $red"Do you still want to continue merging? (Y/N)"
        read mergeable
      fi

      if [ "$mergeable" = "Y" ]; then
        echo -e $green"Succeeded. Merging..."
        git checkout --quiet master

        echo -e "Merging $current_branch to master"
        git merge --ff-only $current_branch

        echo -e $green"Merged. Pushing to master..."
        git push origin master

        echo -e $green"Cleaning up"
        git push origin --quiet :$current_branch # delete remote branch
        git branch -D --quiet $current_branch # delete local branch

        echo -e $green"\n$current_branch has been merged to master"
        echo -e $green"$current_branch has been deleted from remote repository"
        echo -e $green"$current_branch has been deleted from local repository\n"
      else
        echo $red"Merge aborted..."
      fi
    fi
  fi
}


