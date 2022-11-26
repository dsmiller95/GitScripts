# Removing Local GIT Branches with No Remote

If you don't actively clean up old branches in your local git repository, it's very easy for it to get polluted with old branches which have been deleted on the remote repository. Worst case this will make listing your local branches almost useless! I believe `git branch` should show a relevant listing of active work that you have checked out, not a list of every branch you've ever checked out locally. Fortunately, there is an easy way around this, if we're willing to put in a little bit of work into automating it.

## TL;DR: Just Give Me the Script

This is the finished product, safeguards and all. Run this from a bash or shell terminal and follow the prompts, and your local repository should get cleaned up. Read on for a more detailed explanation, or skip to [making it a git command](#Registering-as-git-command).

```bash
#!/usr/bin/env sh
if !(git rev-parse --is-inside-work-tree); then
	echo "Not inside a git repository, aborting"
	exit 0
fi

git remote prune origin

git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals
cat locals | grep -xv -f remotes > branchesToDelete

# -w checks word counts to ignore blank lines
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
```


## Getting to the Root of It

The process behind identifying dead local branches that we'll use follows a few basic steps:
1. Get lists of remote and local branch names
2. Compare the lists of branches, and keep only local branches which aren't in the list of remote branches
3. Since we will be forcing branch deletion, confirm with the user that we have the right branches before deleting
4. Delete all of the branches resulting from the comparison of the two lists


### Listing the Branches

The only unique requirement when listing out local and remote branches for this purpose is to make sure that the two lists are comparable. We want to be sure that a branch in the remote list can match up exactly with a corresponding branch in the list of local branches. Luckily git gives us the tools we need to format our branches into a clean list:

```bash
git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals
```

#### Breakdown by Phrase
* `git branch`
  * Lists out all local branches by default, adding the `-r` parameter lists only remote branches
* `--format`
  * Gives options to output only specific pieces of information about each branch
* `refname`
  * This part of the format string specifies that we only want the refname field from this branch. This is a complete unique identifier for each branch
  * For local branches, this would look like `refs/heads/master`
  * For remote branches, this would look like `refs/remotes/origin/master`
* `:lstrip=n`
  * This is a modifier on the `refname` field. It is used to specify that the first `n` path sections should be removed from the branch name before it is output. For example, by stripping the first 3 sections off of a remote branch name `refs/remotes/origin/feature/dropdown`, it leaves just `feature/dropdown`. More info on git's formatting syntax is available here: https://git-scm.com/docs/git-for-each-ref#_field_names 
* `> [filename]`
  * Output everything into a file for use later on

### Comparing the Lists

The `grep` command is configurable enough to use it for this purpose by using a few command line options. In effect this configuration attempts to exactly match each line in `locals` against every line in `remotes`, and only output lines from `locals` which do not match.

```bash
cat locals | grep -x -v -f remotes > branchesToDelete
```

#### Breakdown by Phrase
* `cat locals | `
  * Takes the `locals` file and pipes it into the next command. `grep` accepts this piped input
* `grep`
  * The [grep](https://linux.die.net/man/1/grep) command
* `-x`
  * Forces grep to only match full lines, instead of the default of partial matches inside of a line
* `-v`
  * Inverts the output: typically grep would only output the input lines which match, now it will only output lines which do not match
* `-f remotes`
  * Tells grep to attempt to match each input against every line in the `remotes` file

### Deleting the Branches

Once we have a list of all of the branches we want to get rid of, they are looped through, with each one deleted in sequence:

```bash
for branch in `cat branchesToDelete`;
do
    git branch -D $branch
done
```

## Cleaning It Up

So far we have a pretty basic setup that will get us what we need:

```bash
git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals
cat locals | grep -x -v -f remotes > branchesToDelete
for branch in `cat branchesToDelete`;
do
    git branch -D $branch
done
```

But this has a few problems if we want to start using it more reliably. Most obvious is that it leaves a bunch of files lying around! Let's clean those up by adding a `rm` at the end:

```bash
rm branchesToDelete remotes locals
```

### User Input to Protect Active Local Branches

Next up, there's another problem. What if I've got a new local branch that I haven't pushed up yet? That branch would get deleted with what we have now, it'd be nice if I could exclude it from this process. Let's add an option to edit the list of branches right before they get deleted:

```bash
code branchesToDelete -w
```

This opens VSCode to edit the `branchesToDelete` file, and `-w` blocks the script execution until the file is closed. Now I can look through the list that's about to be deleted and make sure there's nothing I care about in there. This could be replaced with any editor command, even `notepad branchesToDelete` would work if you prefer not to use VSCode.

-----

What we have now does well when we're in a git repository, and have some branches to delete, but this might not always be the case when running the script. To finish it up let's add some early exits in case we're not in a repository, or in case we end up with no branches to delete. And a few informational printouts so a new user doesn't feel lost. That leaves us with the final product:

```bash
#!/usr/bin/env sh
if !(git rev-parse --is-inside-work-tree); then
	echo "Not inside a git repository, aborting"
	exit 0
fi

git remote prune origin

git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals
cat locals | grep -xv -f remotes > branchesToDelete

# -w checks word counts to ignore blank lines 
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
```

# Registering as git command

To use this script in multiple repositories easily, it can be set up as a git command so that all it takes to run it is `git clean-branches` from any console. The setup for this is pretty quick:

---
### Create script in /usr/bin/

Copy or create a script to become a git command into your git installation's `/usr/bin/` directory, on Windows it is likely here: `C:\Program Files\Git\usr\bin`.

This can be found on windows by navigating to `/usr/bin/` in a Git bash console, and opening an explorer window at that location with `explorer .`

---
### Set script name
Rename the script based on what you want the name of the command to be. In this case "git-clean-branches", note that there is no `.sh` extension in the name. Git will look for filenames starting with "git-", and take the remaining part of the whole filename as the command's name.

Since there is no file extension there must be a shebang at the start of the file to indicate how the script is to be run (`#!/usr/bin/env sh`)

---
### Done!

Now any terminal that has access to regular Git commands will also have access to your new custom script

# Conclusion

Taking some time to build tools to help yourself or other work a little faster is something that I find can be quite rewarding. I hope that this not only helps clean up your git repos in the future, but also inspires you to look for other ways you can reduce repetitiveness in your workflow with these sorts of tools. Once you start automating things, it's hard to resist continuing to automate.

# About Me

I started my adventure in coding by playing around with coding environments such as [Scratch](https://scratch.mit.edu/), [Processing](https://processing.org/), and [Grobots](http://grobots.sourceforge.net/). After making it through college I got started in web development, working with Angular front-ends and NodeJS or C# back-ends. In my free time I love to play games like Factorio and Noita, or occasionally trying my hand at woodwork.