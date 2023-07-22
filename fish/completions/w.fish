# completions for "w" - git repo switcher for work repositories.
# 1st arg: folder / project. "optional", "w" will automatically fetch a repo if the folder shouldn't exist.
complete --command w --exclusive \
    --condition 'test (count (commandline -opc)) -eq 1' \
    --arguments '(ls ~/Documents/work/)'

# 2nd arg: branch name. This is similar to "c", but passes the directory based on the 1st arg to _c_complete.
complete --command w --exclusive \
    --keep-order \
    --condition 'test (count (commandline -opc)) -eq 2' \
    --arguments '(set --local repo (commandline -opc)[2]; 
set --local opts
if test -d ~/Documents/work/$repo
    set -a opts "--directory" ~/Documents/work/$repo
else
    set -a opts "--repository" $repo
end

_c_complete $opts (commandline -ct)
)'

# 3rd arg: git commit. Similar to 2nd arg, using pushd & popd (we can't do so for second arg because the repo might not
#          exist on disk yet).
complete --command w --exclusive \
    --keep-order \
    --condition 'test (count (commandline -opc)) -eq 3' \
    --arguments '(set --local repo (commandline -opc)[2]
    pushd ~/Documents/work/$repo
    git-pick-commit
    popd
)'
