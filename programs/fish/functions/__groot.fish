# Expansion for the `groot` abbr: path to the worktree/workspace root + cursor.
# A jj workspace has no .git, so `git root` (= rev-parse --show-toplevel) returns
# nothing there — resolve via jj first, then fall back to git for plain-git repos.
set -l root (jj root --ignore-working-copy 2>/dev/null; or git rev-parse --show-toplevel 2>/dev/null)
test -n "$root"; or return 1
echo (realpath --relative-to=(pwd) -- $root)/%
