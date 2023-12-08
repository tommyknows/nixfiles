set -l helptext "c - switch / checkout git branches / worktrees.

c [OPTIONS] [BRANCH_NAME [COMMIT SHA / BRANCH]]

DESCRIPTION
c checks out git branches into worktrees, and switches to the corresponding worktree.
If the branch does not exist, it will be created.
If the worktree does not exist, it will be created.
If no BRANCH_NAME is specified, c will switch to the default branch (main / master).
If no checkout_target or BRANCH is specified and BRANCH_NAME does not exist yet, c will 
check out the new branch at the given checkout_target or BRANCH.
If the BRANCH_NAME starts with 'origin/', a local branch will be checked out with the 
same name as the remote branch. In this case, specifying a COMMIT SHA or BRANCH is invalid.
Effectively, it is a shortcut for doing `c my-branch origin/my-branch`.

Note that this command has a corresponding auto-completion script (_c_complete) to help
pick both BRANCH_NAME and COMMIT SHA / BRANCH. By default, `c <TAB>` will list all local
branches. If the branch name is prefixed with 'o' (e.g. `c o<TAB>`), all origin-branches
will be shown as well to check out. If the branch name is prefixed with 'v', tags will be
shown ('v' for the 'v0.0.0' prefix).

`c <branch-name> <TAB>` will bring up an interactive commit-picker with fuzzy-finding.

The following options are available:

-j or --jira
      Stores a Jira Ticket (in the form [ABC-123]) in git notes for later extraction
      when \"git commit\"ing. Only valid if a new branch / worktree is being created.
      If the currently checked out branch already specifies a Jira Ticket and this
      flag is not set, the value will be copied from the current branch.

-h or --help
      Displays help about using this command.

EXAMPLES
`c` switches to the main branch.
`c new-branch a12346` checks out `new-branch` at the commit SHA `a12346`.
`c feat/my-branch` checks out `feat/my-branch`, and will ensure a sane directory name without slashes.
`c origin/hello` checks out the remote branch `hello` in a new local branch named `hello`.
`c -j PROJ-2048 my-feature` will create a branch `my-feature` corresponding to the Jira Ticket `PROJ-2048`.
"

argparse 'j/jira=' 'h/help' -- $argv

if set --query _flag_help
    printf '%b' $helptext
    return
end

set -l default_branch (default_branch)
set -l local_branch_name (string replace 'origin/' '' "$argv[1]")
set -l checkout_target
set -l track_upstream false
# if these don't match, the user specified to check out an origin/<BRANCH>. 
if test "$local_branch_name" != "$argv[1]"
    set checkout_target "$argv[1]"
    set track_upstream true
end
set -l jira_ticket "$_flag_jira"

# invoking only 'c' without a branch name should switch to the default branch.
if test -z $argv[1]
    set local_branch_name $default_branch
end

# check if there's a target given to check out, and make sure it's valid.
if test -n "$argv[2]" && test -z "$checkout_target"
    if ! git rev-parse --quiet --verify "$argv[2]" &>/dev/null
        echo "invalid commit sha or branch name: $argv[2]"
        return
    end
    set checkout_target "$argv[2]"
end


# the "groot" (git root) is the parent directory of all worktrees, where the .git dir resides.
set -l groot (__bobthefish_dirname (realpath (git rev-parse --git-common-dir 2>/dev/null)))

# if the branch name contains a slash, don't make the dir name annoying.
set dir_name $groot/(string replace -a "/" "_" "$local_branch_name")

# if worktree already exists, switch to that and return!
if git worktree list --porcelain | rg "branch refs/heads/$local_branch_name" &>/dev/null
    cd $dir_name
    return
end

echo -n "Creating worktree for branch $local_branch_name"
if test -n "$checkout_target"
    echo " at $checkout_target"
else
    echo ""
end

if "$track_upstream"
    # Fetch potential changes from the remote.
    echo "Checking out remote branch, pulling changes from remote..."
    git fetch origin $local_branch_name &> /dev/null
end

set -l create_branch_flag ""
# if the branch doesn't exist yet, use `-b` to create it.
if ! git rev-parse --verify --quiet $local_branch_name &>/dev/null
    set create_branch_flag "-b"
end
git worktree add $dir_name $create_branch_flag $local_branch_name $checkout_target &> /dev/null

if [ -d $groot/$default_branch/node_modules ]
    ln -s $groot/$default_branch/node_modules $dir_name/node_modules
end
# TODO: copy other config files?
if [ -f $groot/$default_branch/config.local.json -a ! -f $dir_name/config.local.json ]
    ln -s $groot/$default_branch/config.local.json $dir_name/config.local.json
end

if test -z "$jira_ticket" 
    # this might also return an empty string, which is fine.
    set jira_ticket (git config branch.(git rev-parse --abbrev-ref HEAD).note)
end

if test -n "$jira_ticket"
    git config branch.$local_branch_name.note $jira_ticket
end

cd $dir_name

if "$track_upstream"
    git branch --set-upstream-to=origin/$local_branch_name
end

