# Git Scripts

This is a repository used to collect some useful custom git scripts

## git clean-branches

This script will remove all local branches which are no longer tracked in the remote repository, typically after a pull request completes

## git rewrite-dates <hours>

This script will rewrite the creation date of all local commits since the last commit tracked on the remote/origin branch, distributing them evenly across the last <hours> hours