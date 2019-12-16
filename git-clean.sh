#!/usr/bin/env sh

if !(git rev-parse --is-inside-work-tree); then
	echo "Not inside a git repository, aborting"
	exit 0
fi

git remote prune origin

# more info on the --format option's syntax available here: https://git-scm.com/docs/git-for-each-ref#_field_names
git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals

# with these flags, grep outputs items from the input pipe (locals) which do not exactly match any line of the input file (remotes)
#  this gits us the set of local branches which are not listed when (git branch -r) is run
cat locals | grep -xv -f remotes > branchesToDelete

# -w checks word counts that way we can ignore blank lines
if [ $(wc -w < branchesToDelete) -gt 0 ];
then
	echo "$(wc -l < branchesToDelete) branches without matching remote found, outputting to editor"
	echo "Waiting for editor to close"
	code branchesToDelete -w
	for branch in `cat branchesToDelete`;
	do
		git branch -D $branch
	done
else
	echo "There are no branches to cleanup.";
fi

rm branchesToDelete remotes locals