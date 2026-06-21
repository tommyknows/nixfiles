# gbd - delete the current (or named) git worktree + branch, return to the default
# branch. The git-worktree fallback for `bd` (which is jj-backed). With -r, first
# rebase the default branch onto the branch being deleted (the old `rbd`).
argparse r/rebase -- $argv

set default_branch (default_branch)
set -l _groot (path dirname (realpath (git rev-parse --git-common-dir 2>/dev/null)))

if test (count $argv) -ne 0
    set branch_name $argv[1]
    set dir_name (string replace -a "/" "_" "$branch_name")
    # if the branch to delete is the same branch as we're currently on, switch to
    # the default branch dir first.
    if [ (basename (git rev-parse --show-toplevel)) = $dir_name ]
        gc $default_branch
    end
else
    set branch_name (git rev-parse --abbrev-ref HEAD | string replace 'heads/' '')
    set dir_name (basename (git rev-parse --show-toplevel))
    # remove the current dir from z so that we won't try to jump back.
    z --delete

    gc $default_branch
    # With -r we rebase below instead of pulling.
    if not set -q _flag_rebase
        git pull origin
    end
end

# -r (the old `rbd`): rebase the default branch onto the branch being deleted,
# integrating its commits before teardown.
if set -q _flag_rebase
    git rebase $branch_name; or return 1
end

# We need the if-check in there as with detached heads, we don't want to delete anything
bb "cd $_groot
    and git worktree remove $dir_name
    and if test $branch_name != HEAD
        git branch -D $branch_name
    end"

rm -f ~/.claude/projects/(string replace -a / - $_groot/$dir_name)
