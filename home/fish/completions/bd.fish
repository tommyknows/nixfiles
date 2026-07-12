# completions for the dispatching "bd": in a jj repo, complete jj workspace dirs; in a
# plain git repo, fall back to the git branch picker (matching what bd dispatches to).
function __bd_complete_dispatch
    set -l groot (repo_root 2>/dev/null); or return
    if test -d $groot/.jj/repo
        for d in $groot/*/
            set -l leaf (basename (string trim --right --chars=/ $d))
            test -d $d/.jj; and echo $leaf
        end
    else
        _c_complete (commandline -ct)
    end
end

complete --command bd --exclusive \
    --condition 'test (count (commandline -opc)) -eq 1' \
    --arguments '(__bd_complete_dispatch)'
complete --command bd --short-option r --description 'integrate change into default branch before teardown'
