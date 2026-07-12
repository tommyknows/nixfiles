# completions for "gc" (git checkout fallback). First argument completed by `c_complete` (branch picker), second argument
# - optional - git commit picker.
complete --command gc --exclusive \
    --keep-order \
    --condition 'test (count (commandline -opc)) -eq 1' \
    --arguments '(
set --local opts
_c_complete (commandline -ct)
)'

complete --command gc --exclusive \
    --condition 'test (count (commandline -opc)) -eq 2' \
    --arguments '(git-pick-commit)'
