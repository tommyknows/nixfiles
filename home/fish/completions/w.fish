# completions for the jj-backed "w" - work repo switcher.
# 1st arg: folder / project (optional; w clones it if absent).
complete --command w --exclusive \
    --condition 'test (count (commandline -opc)) -eq 1' \
    --arguments '(command ls ~/Documents/work/)'

# 2nd arg: branch / bookmark name in the selected repo (if it already exists locally).
function __w_jj_refs
    set -l repo (commandline -opc)[2]
    set -l dir ~/Documents/work/$repo
    test -d $dir; or return
    # local jj bookmarks, falling back to git branches in the bare store.
    jj -R $dir bookmark list -T 'name ++ "\n"' 2>/dev/null
    git -C $dir/.git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null
end

complete --command w --exclusive \
    --keep-order \
    --condition 'test (count (commandline -opc)) -eq 2' \
    --arguments '(__w_jj_refs)'
