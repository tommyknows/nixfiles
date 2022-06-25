# completions for "w" - git repo switcher for work repositories.
# 1st arg: folder / project. "optional", "w" will automatically fetch a repo if the folder shouldn't exist.
# 2nd arg: branch name. This is similar to "c", but passes the directory based on the 1st arg to c_complete.
# 3rd arg: git commit. Similar to 2nd arg, using pushd & popd (we can't do so for second arg because the repo might not
#          exist on disk yet).
complete --command w -x --condition 'test (count (commandline -opc)) -lt 2' --arguments '(ls ~/Documents/work/)'
complete --command w -x --keep-order --condition 'test (count (commandline -opc)) -eq 2' --arguments '(c_complete ~/Documents/work/(commandline -opc)[2])'
complete --command w -x --condition 'test (count (commandline -opc)) -eq 3' --arguments '(pushd ~/Documents/work/(commandline -opc)[2] && git-pick-commit && popd)'
