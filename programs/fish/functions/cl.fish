set -l _git_common (git rev-parse --git-common-dir 2>/dev/null)
if test $status -ne 0
    claude $argv
    return
end

argparse a/attach -- $argv

set -l _groot (path dirname (realpath $_git_common))

function _cl_invoke --no-scope-shadowing
    set -l _dir $argv[1]
    set -l _rest $argv[2..]
    if set -q _flag_attach; and test -f $_dir/.claude/session; and not string match -q -- '--resume*' $_rest
        subagent-attach $_dir $_rest
    else
        claude $_rest
    end
end

# Mode 1: cl . — scope to current worktree only
if test (count $argv) -ge 1; and test "$argv[1]" = .
    _cl_invoke (pwd) $argv[2..]
    return
end

# Mode 2: cl <repo> <branch> — named repo + branch (two non-flag args)
if test (count $argv) -ge 2; and not string match -q -- '-*' "$argv[1]"; and not string match -q -- '-*' "$argv[2]"
    set -l _repo_path
    if test "$argv[1]" = nixfiles
        set _repo_path /Users/ramon/Documents/nixfiles
    else if test -d /Users/ramon/Documents/work/$argv[1]
        set _repo_path /Users/ramon/Documents/work/$argv[1]
    end

    if test -n "$_repo_path"
        set -l _target $_repo_path/$argv[2]
        if not test -d $_target; or not test -e $_target/.git
            echo "cl: branch '$argv[2]' not found in $_repo_path"
            return 1
        end
        cd $_target
        _cl_invoke $_target $argv[3..]
        return
    end
end

# Mode 3: cl <branch> — single non-flag arg treated as branch in current repo
if test (count $argv) -eq 1; and not string match -q -- '-*' "$argv[1]"
    set -l _candidate $_groot/$argv[1]
    if test -d $_candidate; and test -e $_candidate/.git
        cd $_candidate
        _cl_invoke $_candidate
        return
    end
end

# Mode 4 (default): add all sibling worktrees as --add-dir
set -l _add_dirs
for dir in $_groot/*/
    set dir (string trim --right --chars=/ $dir)
    if test -e $dir/.git; and test $dir != (pwd)
        set _add_dirs $_add_dirs --add-dir $dir
    end
end

_cl_invoke (pwd) $_add_dirs $argv
