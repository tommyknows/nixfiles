# rbd is like bd, but rebases main on top of the branch we're deleting.
set branch_name (git rev-parse --abbrev-ref HEAD | string replace 'heads/' '')
# c without arguments checks out the default branch
c

git rebase $branch_name || exit 1
bd $branch_name
