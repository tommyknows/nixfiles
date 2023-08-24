set -l default_branch (default_branch)
set -l branch_name (string replace 'origin/' '' "$argv[1]")
if [ -z $argv[1] ] 
    set branch_name $default_branch
end

set create_local_branch false
if ! git rev-parse --verify --quiet $branch_name &>/dev/null
    set create_local_branch true
end
# the "groot" (git root) is the parent directory of all worktrees and the .git dir.
set -l groot (__bobthefish_dirname (realpath (git rev-parse --git-common-dir 2>/dev/null)))

# if the branch name contains a slash, don't make the dir name annoying.
set dir_name $groot/(string replace -a "/" "_" "$branch_name")

# only create the worktree if it does not exist yet.
if ! git worktree list --porcelain | rg "branch refs/heads/$branch_name" &>/dev/null
    echo -n "Creating worktree for branch $branch_name"
    set commit_sha
    if test (count $argv) -gt 1
        set commit_sha "$argv[2]"
        echo -n " at commit $commit_sha"
    else if test $branch_name != $argv[1]
        set commit_sha "$argv[1]"
        echo -n " at remote branch $argv[1]"
        set track_upstream true

        # check if we have the remote branch fetched, and if not, pull
        if ! git branch --remotes --quiet | rg "$argv[1]"
            echo "Pulling changes from remote..."
            git pull &> /dev/null
        end
    end

    if $create_local_branch
        git worktree add -b $branch_name $dir_name $commit_sha &> /dev/null
    else
        git worktree add $dir_name $branch_name $commit_sha &> /dev/null
    end

    if set --query $track_upstream
        git branch --set-upstream-to=origin/$branch_name
    end

    if [ -d $groot/$default_branch/node_modules ]
        ln -s $groot/$default_branch/node_modules $dir_name/node_modules
    end
    echo ""
end

cd $dir_name
