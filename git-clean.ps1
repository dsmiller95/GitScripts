If (!(git rev-parse --is-inside-work-tree)) {
    Write-Output "Not inside a git repository, aborting"
    exit 0
}
git remote prune origin
# more info on the --format option's syntax available here: https://git-scm.com/docs/git-for-each-ref#_field_names
git branch -r --format "%(refname:lstrip=3)" > remotes
git branch --format "%(refname:lstrip=2)" > locals
# with these flags, Select-String outputs items from the input pipe (locals) which do not exactly match any line of the input file (remotes)
# this gits us the set of local branches which are not listed when (git branch -r) is run
Get-Content locals | Select-String -Pattern (Get-Content remotes) -NotMatch > branchesToDelete
# strip empty lines from branchesToDelete
(Get-Content ./branchesToDelete) | Where-Object { $_ } | Set-Content ./branchesToDelete
# -Words checks word counts that way we can ignore blank lines
$words = (Get-Content .\branchesToDelete | Measure-Object -Word).Words
If ($words -gt 0) {
    Write-Output "$($words) branches without matching remote found, outputting to editor"
    Write-Output "Waiting for editor to close"
    code branchesToDelete -w
    if ($?) {
        Get-Content .\branchesToDelete | ForEach-Object {
            git branch -D $_
        } 
    }
}
Else {
    Write-Output "There are no branches to cleanup";
}
Remove-Item branchesToDelete, remotes, locals