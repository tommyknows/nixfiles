set repo_name $argv[1]
set clone_path $argv[2]
if [ -z "$argv[2]" ]
    set clone_path (string split --right --max=1 "/" $repo_name)[-1]
end

echo "Cloning repository github.com/$repo_name to $clone_path..."
mkd $clone_path > /dev/null
# we only want to clone the .git directory, not checkout anything. Additionally, `--bare` implies:
# > the branch heads at the remote are copied directly to corresponding local branch heads
# We don't want that, so we specify --single-branch.
git clone --bare --single-branch "git@github.com:$repo_name.git" ./.git 2>/dev/null

echo "Fetching references..."
git fetch origin 'refs/heads/*:refs/remotes/origin/*' 2&>/dev/null
git remote set-head origin -a

set default_branch (git remote show origin | sed -n '/HEAD branch/s/.*: //p')
echo "Creating default worktree \"$default_branch\""
git worktree add $default_branch $default_branch 2&> /dev/null

cd $default_branch
