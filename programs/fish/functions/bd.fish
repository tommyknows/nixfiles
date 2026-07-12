# `bd` — tear down a worktree/workspace and return to the default branch.
#
# Dispatches on repo type: a jj repo (<root>/.jj/repo) tears down jj workspaces;
# a plain git repo falls back to `gbd` (git worktrees). Call `gbd` directly to force
# the git behavior.

argparse r/rebase h/help -- $argv

if set --query _flag_help
    printf '%b' "bd - tear down the current/named jj workspace + bookmark, return to default.
bd [-r] [NAME]    -r: integrate the change into the default branch first (old rbd).
In a plain git repo this dispatches to gbd (git worktrees).
"
    return
end

set -l groot (repo_root)
if test $status -ne 0
    gbd $argv
    return
end
if not test -d $groot/.jj/repo
    # Plain git repo → git-worktree teardown. Forward the rebase flag.
    if set -q _flag_rebase
        gbd -r $argv
    else
        gbd $argv
    end
    return
end

# -------------------------------- jj teardown --------------------------------
set -l default_branch (default_branch)

# Resolve the target workspace leaf (dir name). NAME may be given as either the
# bookmark ('chore/foo') or the dir leaf ('chore_foo'); both map to the same leaf.
set -l dir_leaf
if set -q argv[1]
    set dir_leaf (string replace -a "/" "_" -- "$argv[1]")
else
    set -l wsroot (jj workspace root 2>/dev/null)
    if test -z "$wsroot"
        echo "bd: not inside a jj workspace; pass a NAME" >&2
        return 1
    end
    set dir_leaf (basename $wsroot)
end
set -l dir $groot/$dir_leaf

if not test -d $dir/.jj
    echo "bd: no jj workspace at $dir" >&2
    return 1
end

# Recover the *real* bookmark name (slashes preserved) from the workspace itself —
# the dir leaf is lossy ('/' → '_'), so we can't reconstruct it by string ops. The
# bookmark usually sits on @'s parent (the working copy is an empty child), so take
# the tip-most bookmark in @'s ancestry; fall back to the dir leaf if there is none.
set -l name (jj -R $dir log --no-graph --no-pager -r 'heads(bookmarks() & ::@)' -T 'local_bookmarks.map(|b| b.name() ++ "\n")' 2>/dev/null)[1]
test -z "$name"; and set name $dir_leaf

# -r: capture the tip to fold into the default branch *before* we move away.
set -l integrate_rev
if set -q _flag_rebase
    set integrate_rev (jj -R $dir log --no-graph --no-pager -r @ -T change_id 2>/dev/null | string trim)
end

# If we're standing in the workspace we're about to delete, leave first.
set -l here (realpath (pwd) 2>/dev/null)
if test "$here" = (realpath $dir 2>/dev/null)
    z --delete
    c $default_branch
end

# Let jj voice the teardown (consistent jj-style log instead of custom echoes).
if set -q _flag_rebase; and test -n "$integrate_rev"
    jj -R $groot bookmark set $default_branch -r $integrate_rev --allow-backwards
end

jj -R $groot workspace forget $dir_leaf
if test "$name" != "$default_branch"
    jj -R $groot bookmark delete $name
end
# The workspace is forgotten from jj's store above, so the on-disk dir is now
# just orphaned files — `rm -rf` is the only slow step, so background it (à la
# gbd) instead of blocking the prompt on a large worktree delete.
bb "rm -rf $dir"
rm -f ~/.claude/projects/(string replace -a / - $dir)
