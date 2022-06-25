# completions for "c" (git checkout). First argument completed by `c_complete` (branch picker), second argument
# - optional - git commit picker.
complete --command c -x --keep-order --condition 'test (count (commandline -opc)) -lt 2' --arguments '(c_complete)'
complete --command c -x --condition 'test (count (commandline -opc)) -eq 2' --arguments '(git-pick-commit)'
