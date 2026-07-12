# clone <owner/repo> [path] [-g|--git]
#
# Clones into the per-branch-directory layout. By default the repo is fully jj-native:
# a bare .jj store at the root (no .git), the default branch as a sibling jj workspace.
# jj handles GitHub fetch/push directly, so no git compatibility layer is needed.
#
# Pass -g/--git for the legacy plain-git bare-clone layout (bare .git + git worktree),
# used by `gw` and for repos you want to keep on git for now. Existing git repos can be
# converted later with `jj-init`; git remains a transitional fallback there.
argparse g/git -- $argv

set repo_name $argv[1]
set clone_path $argv[2]
if [ -z "$argv[2]" ]
    set clone_path (string split --right --max=1 "/" $repo_name)[-1]
end

# check if repo exists
if ! git ls-remote https://github.com/$repo_name > /dev/null
    echo "Repository $repo_name does not exist!"
    return
end

echo "Cloning repository github.com/$repo_name to $clone_path..."

if set -q _flag_git
    # ---- legacy plain-git bare-clone layout ----
    mkd $clone_path > /dev/null
    # we only want to clone the .git directory, not checkout anything. `--bare` implies
    # copying remote heads to local heads, which we don't want, hence --single-branch.
    git clone --bare --single-branch "git@github.com:$repo_name.git" ./.git 2>/dev/null

    echo "Fetching references..."
    # mirror what a normal `git clone` sets locally (a bare clone doesn't).
    git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git fetch origin 2&>/dev/null
    git remote set-head origin -a

    set default_branch (git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    echo "Creating default worktree \"$default_branch\""
    git worktree add $default_branch $default_branch 2&> /dev/null

    cd $default_branch
else
    # ---- jj-native clone ----
    # jj git clone creates the bare .jj store + a default working copy at the root, sets
    # up the origin remote, fetches, and tracks the default bookmark.
    if not jj git clone --no-colocate "git@github.com:$repo_name.git" $clone_path
        echo "clone: jj git clone failed"
        return 1
    end
    cd $clone_path
    # Empty the root checkout, then forget the default workspace, so the root holds only
    # the bare .jj store (the analogue of a bare .git) and never snapshots stray files.
    jj new 'root()' 2>/dev/null
    jj workspace forget default 2>/dev/null

    set default_branch (default_branch)
    echo "Creating default workspace \"$default_branch\""
    jj workspace add --name $default_branch -r $default_branch (pwd)/$default_branch
    __jj_ws_links (pwd) (pwd)/$default_branch $default_branch

    cd $default_branch
end

repo-init
