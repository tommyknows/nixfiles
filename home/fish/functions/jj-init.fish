set -l helptext "jj-init - convert the current git repo (bare-clone + worktrees) to jj.

jj-init [-h]

DESCRIPTION
Explicitly and atomically converts the whole current repo from git worktrees to jj
workspaces. This is the ONLY command that converts a repo — `c`/`w`/`bd` merely
dispatch on whether the repo is already jj. After conversion:

    <repo>/
      .git/      bare git store (shared; refs stay authoritative)
      .jj/       bare jj store at the root (default workspace forgotten)
      main/      jj workspace (was a git worktree)
      <branch>/  jj workspace

ALL-OR-NOTHING: every existing worktree must be clean (no uncommitted changes and no
non-ignored untracked files). If any is dirty, jj-init aborts and touches nothing —
a jj store with no converted workspaces would flip `c`/`w` into jj-mode over still-git
worktrees. Commit/stash the listed trees and re-run.

Each worktree (incl. main/master) is removed and re-created as a jj workspace at the
same branch; ignored files (node_modules, .claude, build output) are recreated via the
usual symlinks. Only the bare git worktree remains afterwards.
"

argparse h/help -- $argv
if set --query _flag_help
    printf '%b' $helptext
    return
end

set -l groot (repo_root)
if test $status -ne 0
    echo "jj-init: not inside a git repository" >&2
    return 1
end
set -l bare $groot/.git
if not test -d $bare
    echo "jj-init: no bare .git at $groot — nothing to convert (native jj clone?)" >&2
    return 1
end

if test -d $groot/.jj/repo
    echo "jj-init: $groot is already a jj repo — nothing to do."
    return 0
end

# Parse `git worktree list --porcelain` into parallel path/branch lists, skipping the
# bare entry. Branch defaults to the HEAD sha for detached worktrees.
set -l wt_paths
set -l wt_revs
set -l p ""
set -l b ""
set -l h ""
set -l is_bare 0
function __jj_init_flush --no-scope-shadowing
    if test -n "$p"; and test $is_bare -eq 0
        set -a wt_paths $p
        if test -n "$b"
            set -a wt_revs $b
        else
            set -a wt_revs $h
        end
    end
end
for line in (git --git-dir=$bare worktree list --porcelain)
    if string match -q 'worktree *' -- $line
        __jj_init_flush
        set p (string replace 'worktree ' '' -- $line)
        set b ""; set h ""; set is_bare 0
    else if string match -q 'HEAD *' -- $line
        set h (string replace 'HEAD ' '' -- $line)
    else if string match -q 'branch refs/heads/*' -- $line
        set b (string replace 'branch refs/heads/' '' -- $line)
    else if test "$line" = bare
        set is_bare 1
    end
end
__jj_init_flush
functions -e __jj_init_flush

if test (count $wt_paths) -eq 0
    echo "jj-init: no git worktrees found to convert." >&2
    return 1
end

# PRE-FLIGHT (before touching anything): every worktree must be clean.
set -l dirty
for path in $wt_paths
    set -l st (git -C $path status --porcelain 2>/dev/null)
    if test -n "$st"
        set -a dirty $path
    end
end
if test (count $dirty) -gt 0
    echo "jj-init: aborting — these worktrees have uncommitted/untracked changes:" >&2
    for d in $dirty
        echo "  $d" >&2
    end
    echo "Commit or stash them, then re-run jj-init." >&2
    return 1
end

echo "Converting "(count $wt_paths)" worktree(s) under $groot to jj workspaces..."

# Remember where we were so we can return there afterwards, then step out to the repo
# root: the removal loop deletes worktree dirs, and deleting the shell's cwd would
# break every subsequent command ("cannot read current working directory").
set -l origin_leaf (basename (pwd))
cd $groot

# Ensure the git interop refspec, then init the bare jj store at the root. Incidental
# setup steps are silenced; jj voices the per-workspace creation below (like `c`).
git -C $bare config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
if not jj git init --no-colocate --git-repo=$bare $groot 2>/dev/null
    echo "jj-init: jj git init failed" >&2
    return 1
end
# Empty the root checkout (jj git init checks trunk out into the root) BEFORE
# forgetting the default workspace — otherwise the tree is left littered at the root.
jj -R $groot new 'root()' 2>/dev/null
jj -R $groot workspace forget default 2>/dev/null

# Refresh remote refs, then track ONLY the local branches we just imported (the
# worktree branches) to their origin upstreams, so future fetch/push know them.
# We deliberately do NOT track every remote bookmark: that would mirror the whole
# remote branch namespace into local bookmarks. (jj's git.auto-local-bookmark
# defaults to false, so a plain fetch won't recreate them either — remote-only
# branches stay as `name@origin`.)
jj -R $groot git fetch 2>/dev/null
for bm in (jj -R $groot bookmark list -T 'name ++ "\n"' 2>/dev/null)
    jj -R $groot bookmark track $bm --remote=origin 2>/dev/null
end

set -l default_branch (default_branch)

# Convert each worktree: remove the git worktree (--force: pre-flight already proved
# it clean; this only clears ignored files like node_modules/.claude), then re-create
# it as a jj workspace at the same branch and restore the shared symlinks.
for i in (seq (count $wt_paths))
    set -l path $wt_paths[$i]
    set -l rev $wt_revs[$i]
    set -l leaf (basename $path)
    git --git-dir=$bare worktree remove --force $path 2>/dev/null
    if jj -R $groot workspace add --name $leaf -r $rev $path
        __jj_ws_links $groot $path $default_branch
    else
        echo "jj-init: failed to create workspace for $leaf (rev $rev)" >&2
    end
end

# Return to the workspace we started in (now a jj workspace), else the default branch.
if test -d $groot/$origin_leaf
    cd $groot/$origin_leaf
else if test -d $groot/$default_branch
    cd $groot/$default_branch
end

echo "Done. `c`/`w`/`bd` now use jj in this repo (use gc/gw/gbd to force git)."
