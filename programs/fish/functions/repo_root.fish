# repo_root — print the repo root: the directory holding the bare store.
#
# Works WITHOUT git, across all our layouts:
#   - jj-native (new clones): only a bare .jj at the root, no .git at all.
#   - hybrid jj (existing repos converted by jj-init): bare .git + bare .jj at root.
#   - plain-git bare-clone: bare .git at root.
#
# The root is the first ancestor whose .jj/repo OR .git is a *directory*. Workspace /
# worktree pointers (`<leaf>/.jj/repo`, `<leaf>/.git`) are *files*, so we walk past
# them and stop at the real store. Returns nonzero when not inside a repo.
set -l d (realpath (pwd) 2>/dev/null); or return 1
while true
    if test -d $d/.jj/repo; or test -d $d/.git
        echo $d
        return 0
    end
    test "$d" = /; and break
    set d (path dirname $d)
end
return 1
