#!/usr/bin/env sh

if [ "$#" -ne 1 ] || ! [ "`git branch --list master`" ] && ! [ "$1" == "-" ]
then
  echo "Usage: git rebase-switch-pull GIT_BRANCH" >&2
  exit 1
fi

IS_REBASE_IN_PROGRESS='[ -d "git/rebase-apply" ] || [ -d ".git/rebase-merge" ]'

if [[ $($IS_REBASE_IN_PROGRESS) ]] 
then
	echo "rebase in progress. aborting."
	exit 1
fi

TARGET_BRANCH=$1


git checkout $1 && git pull --rebase && git checkout - && git rebase - && echo "updated local branch"

