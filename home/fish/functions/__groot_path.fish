# jj workspaces have no .git, so resolve the worktree/workspace root via jj
# first, falling back to git (= `git root`) for plain-git repos.
set -l root (jj root --ignore-working-copy 2>/dev/null; or git rev-parse --show-toplevel 2>/dev/null)
if test -z "$root"
    return 1
end
set -l rel (realpath --relative-to=(pwd) -- $root)
set -l rest (string sub -s 3 -- $argv[1])
if test -z "$rest"
    echo $rel/%
else
    echo $rel/$rest%
end
