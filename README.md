# Git Scripts

This is a repository used to collect some useful custom git scripts. Run `install.sh` once per computer, to link up the git command path. To test changes to the scripts, or to apply newly pulled down changes, run `deploy.sh` every time scrips change

## git clean-branches

This script will remove all local branches which are no longer tracked in the remote repository, typically after a pull request completes

## git rewrite-dates [hours]

This script will rewrite the creation date of all local commits since the last commit tracked on the remote/origin branch, distributing them evenly across the last [hours] hours

## git rebase-switch-pull [branch]

Switch to [branch], pull, switch back, rebase onto [branch]
