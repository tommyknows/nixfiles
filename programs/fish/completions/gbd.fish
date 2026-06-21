# completions for "gbd" (git-worktree teardown fallback): branch / worktree picker.
complete --command gbd --exclusive \
    --keep-order \
    --condition 'test (count (commandline -opc)) -eq 1' \
    --arguments '(
set --local opts
_c_complete (commandline -ct)
)'
complete --command gbd --short-option r --description 'rebase default branch onto this branch before deleting'
