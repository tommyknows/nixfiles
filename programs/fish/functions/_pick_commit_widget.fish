# _pick_commit_widget — commandline widget that opens the change/commit
# picker and inserts the chosen id at the cursor. 
set -l groot (repo_root 2>/dev/null)
set -l id
if test -n "$groot" -a -d "$groot/.jj/repo"
    set id (jj-pick-change)
else
    set id (git-pick-commit)
end
test -n "$id"; and commandline -it -- "$id"
commandline -f repaint
