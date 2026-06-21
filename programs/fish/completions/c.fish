# completions for the dispatching "c": in a jj repo, complete existing workspaces +
# bookmarks; in a plain git repo, fall back to the git branch picker (_c_complete),
# matching what `c` dispatches to (gc). With -o/--origin, complete remote branch
# names only (so you can narrow to remotes easily).
function __c_complete_dispatch
    set -l groot (repo_root 2>/dev/null); or return
    if test -d $groot/.jj/repo
        # jj repo: sibling workspace dirs (switch targets) + local bookmarks +
        # remote bookmarks as origin/<name> (so `c origin/<tab>` resolves).
        for d in $groot/*/
            set -l leaf (basename (string trim --right --chars=/ $d))
            test -d $d/.jj -o -e $d/.git; and echo $leaf
        end
        jj -R $groot bookmark list -T 'name ++ "\n"' 2>/dev/null
        jj -R $groot bookmark list -a -T 'if(remote == "origin", "origin/" ++ name ++ "\n")' 2>/dev/null
    else
        # plain git repo: same branch picker `gc` uses.
        _c_complete (commandline -ct)
    end
end

# remote (origin) branch names only — offered when -o/--origin is present.
function __c_remote_bookmarks
    set -l groot (repo_root 2>/dev/null); or return
    if test -d $groot/.jj/repo
        jj -R $groot bookmark list -a -T 'if(remote == "origin", name ++ "\n")' 2>/dev/null
    else
        # git repo: remote-tracking branch short names (origin/foo → foo).
        git -C $groot/.git for-each-ref --format='%(refname:short)' refs/remotes/origin 2>/dev/null \
            | string replace 'origin/' '' | string match -v HEAD
    end
end

# With -o/--origin: remote branch names only.
complete --command c --exclusive \
    --condition '__fish_contains_opt -s o origin' \
    --arguments '(__c_remote_bookmarks)'

# 1st positional (no -o): workspaces + local bookmarks + origin/<name>.
complete --command c --exclusive \
    --condition 'not __fish_contains_opt -s o origin; and test (count (commandline -opc)) -eq 1' \
    --arguments '(__c_complete_dispatch)'

# 2nd positional (no -o): base/commit. jj repo → bookmarks (revset base); git → commit picker.
complete --command c --exclusive \
    --keep-order \
    --condition 'not __fish_contains_opt -s o origin; and test (count (commandline -opc)) -eq 2' \
    --arguments '(
set -l groot (repo_root 2>/dev/null); or exit
if test -d $groot/.jj/repo
    jj -R $groot bookmark list -T "name ++ \"\n\"" 2>/dev/null
else
    git-pick-commit
end
)'

# flags
complete --command c --short-option o --long-option origin --description 'check out / track a remote (origin) branch'
complete --command c --short-option t --long-option ticket --require-parameter --description 'store a ticket reference for commits'
complete --command c --short-option h --long-option help --description 'show help'
