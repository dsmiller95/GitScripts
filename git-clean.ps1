If (!(git rev-parse --is-inside-work-tree)) {
    Write-Output "Not inside a git repository, aborting"
    exit 0
}

git remote prune origin

# more info on the --format option's syntax available here: https://git-scm.com/docs/git-for-each-ref#_field_names
$remotes = git branch -r --format "%(refname:lstrip=3)"
$locals = git branch --format "%(refname:lstrip=2)"

# with these flags, Select-String outputs items from the input pipe (locals) which do not exactly match any line of the input file (remotes)
# this gits us the set of local branches which are not listed when (git branch -r) is run
$branchesToDelete = $locals | Select-String -Pattern $remotes -NotMatch

# -Words checks word counts that way we can ignore blank lines
$words = ($branchesToDelete | Measure-Object -Word).Words
If ($words -gt 0) {
    Write-Output "$($words) branches without matching remote found, outputting to editor"
    Write-Output "Waiting for editor to close"

    # create file with branches staged for deletion with informational text and remove blank lines
    $info = "************************************`nRemove Branch Names You Wish To Keep`nSave & Close File To Continue`n************************************"
    Write-Output $info | Set-Content branchesToDelete
    $branchesToDelete | Where-Object { $_ } | Add-Content branchesToDelete
    # open file in VSCode to allow user to opt out of deleting specified branches
    code branchesToDelete -w

    # make sure VSCode ran successfully before deleting branches
    if ($?) {
        # skip first 4 lines of file which are informational text for the user and lines that are blank
        Get-Content branchesToDelete | Select-Object -Skip 4 | Where-Object { $_ } | ForEach-Object {
            git branch -D $_
        } 
    }

    Remove-Item branchesToDelete
}
Else {
    Write-Output "There are no branches to cleanup";
}