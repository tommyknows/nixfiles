set default_branch (default_branch)

if test (count $argv) -ne 0
    set branch_name $argv[1]
    set dir_name (string replace -a "/" "_" "$branch_name")
    # if the branch to delete is the same branch as we're currently on, switch to 
    # the default branch dir first.
    if [ (basename (git rev-parse --show-toplevel)) == $dir_name ]
        c $default_branch
    end
else
    set branch_name (git rev-parse --abbrev-ref HEAD | string replace 'heads/' '')
    set dir_name (basename (git rev-parse --show-toplevel))
    # remove the current dir from z so that we won't try to jump back.
    z --delete

    c $default_branch
    git pull origin
end

git worktree remove $dir_name
# with detached heads, we don't want to delete anything.
if [ $branch_name != "HEAD" ]
    git branch -D $branch_name
end
