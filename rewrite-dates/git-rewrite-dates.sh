#!/usr/bin/env sh

IS_REBASE_IN_PROGRESS='[ -d "git/rebase-apply" ] || [ -d ".git/rebase-merge" ]'

if [[ $($IS_REBASE_IN_PROGRESS) ]] 
then
	echo "rebase in progress. aborting."
	exit 1
fi

CURRENT_DATE=$(date +%s)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TOTAL_COMMITS=$(git rev-list origin/$CURRENT_BRANCH..$CURRENT_BRANCH | wc -l)
if [ $TOTAL_COMMITS -le 0 ]
then
	echo "no commits to rewrite, branch is up to date"
	exit 0
fi
TOTAL_TIME_HOURS=$1
echo Rewriting across $TOTAL_TIME_HOURS hours.
TOTAL_TIME_SECONDS=$(($1 * 60 * 60))
if [ $TOTAL_COMMITS -le 1 ]
then
	SECONDS_PER_COMMIT=0
	VARIATION_PER_COMMIT=1
	INITIAL_COMMIT_TIME=$CURRENT_DATE
else
	SECONDS_PER_COMMIT=$(((TOTAL_TIME_SECONDS * 2)/(TOTAL_COMMITS * 2 - 2 + 1))) # TOTAL_TIME_SECONDS/(TOTAL_COMMITS - 1 + 0.5) , but integer math only
	VARIATION_PER_COMMIT=$((SECONDS_PER_COMMIT / 4)) #add this amount +/- to each commit time individually. pads the seconds per commit, and initial commit time, accordingly
	INITIAL_COMMIT_TIME=$((CURRENT_DATE-TOTAL_TIME_SECONDS+VARIATION_PER_COMMIT))
fi
echo "per commit:			$(date -u -d @${SECONDS_PER_COMMIT} +"%T") h:m:s +/-  $(date -u -d @${VARIATION_PER_COMMIT} +"%T") h:m:s"
echo "earliest possible commit:	$(date --date @$INITIAL_COMMIT_TIME)"

echo $SECONDS_PER_COMMIT > per_commit
echo $INITIAL_COMMIT_TIME > current_time
#trap "rm per_commit current_time" EXIT

NEXT_COMMIT_TIME_VAL="\$((\$(cat current_time) + (\$RANDOM % ($VARIATION_PER_COMMIT * 2) - $VARIATION_PER_COMMIT)))"

trap "rm per_commit current_time || echo && git rebase --abort 2>/dev/null && echo error encountered, aborting rebase" EXIT
git rebase origin/$(git rev-parse --abbrev-ref HEAD) --exec "git commit --amend --allow-empty --date=$NEXT_COMMIT_TIME_VAL --no-edit && echo \$((\$(cat current_time)+\$(cat per_commit))) > current_time"