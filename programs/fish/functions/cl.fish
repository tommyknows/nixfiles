set -l _git_common (git rev-parse --git-common-dir 2>/dev/null)
if test $status -ne 0
    claude $argv
    return
end

set -l _groot (path dirname (realpath $_git_common))

set -l _add_dirs
for dir in $_groot/*/
    set dir (string trim --right --chars=/ $dir)
    if test -e $dir/.git; and test $dir != (pwd)
        set _add_dirs $_add_dirs --add-dir $dir
    end
end

claude $_add_dirs $argv
