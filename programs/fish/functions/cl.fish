argparse --ignore-unknown a/attach n/no-sandbox 'wt=+' -- $argv
or return

# --wt=<dir> (repeatable): grant the sandbox RW access to a worktree. If <dir>
# is a linked git worktree, its git-common-dir (the bare .git/) is added too —
# otherwise git ops fail because per-worktree state lives outside the worktree.
# Falls back to a plain RW grant for non-git paths.
if set -q _flag_wt
    set -l _expanded
    for d in $_flag_wt
        # Fish doesn't expand `~/` mid-word (e.g. in --wt=~/foo), so do it here.
        set d (string replace -r '^~/' "$HOME/" -- $d)
        test -e $d; or continue
        set d (realpath $d)
        set -a _expanded $d
        # If <d> is a linked git worktree, also grant RW to its common dir.
        set -l _gc (git -C $d rev-parse --git-common-dir 2>/dev/null); or continue
        string match -q '/*' $_gc; or set _gc $d/$_gc
        set _gc (realpath $_gc 2>/dev/null); and set -a _expanded $_gc
    end
    set _flag_wt $_expanded
end

# Sets _cl_tilt to "1" if any argument dir contains a Tiltfile.
# Trips the docker + scoped-kubeconfig path inside _cl_make_cmd.
function _cl_detect_tilt --no-scope-shadowing
    set _cl_tilt
    for dir in $argv
        if test -f $dir/Tiltfile
            set _cl_tilt 1
            return
        end
    end
end

# Build the claude command (sandboxed by default; -n/--no-sandbox opts out).
# Defined as a helper so mode 4 can rebuild with extra RW paths for siblings.
function _cl_make_cmd --no-scope-shadowing
    if set -q _flag_no_sandbox
        set _claude_cmd claude
        return
    end
    set -l _rw $HOME/Documents/go $HOME/Library/Caches/go-build $argv $_flag_wt
    set -l _safehouse_args \
        --add-dirs=(string join : $_rw) \
        --add-dirs-ro=$HOME/Documents/work:$HOME/Documents/nixfiles \
        --append-profile=$HOME/.config/agent-safehouse/local-overrides.sb \
        --env-pass=GITHUB_TOKEN \
        --env-pass=TEST_DB_URL \
        --env-pass=TEST_LOCALSTACK_ENDPOINT \
        --env-pass=TMUX \
        --env-pass=TMUX_PANE
    set -l _env_prefix
    if test -n "$_cl_tilt"
        set _safehouse_args $_safehouse_args --enable=docker --env-pass=KUBECONFIG
        set _env_prefix env KUBECONFIG=$HOME/.kube/configs/tilt
        echo "cl: Tiltfile detected — enabling docker socket + scoped kubeconfig (~/.kube/configs/tilt)" >&2
    end
    set _claude_cmd $_env_prefix safehouse $_safehouse_args -- claude --dangerously-skip-permissions
end

# Run claude with a tmux pane marker so vim's <leader>cl can find this
# session and inject prompts via tmux paste-buffer. Marker is the cwd
# (= worktree); cleared after claude exits. Stale markers can survive
# `exec` or kill -9 — vim cross-checks before pasting.
function _cl_marked_run --no-scope-shadowing
    if set -q TMUX
        tmux set-option -p @claude-session (pwd) 2>/dev/null
        $_claude_cmd $argv
        set -l _rc $status
        tmux set-option -p -u @claude-session 2>/dev/null
        tmux set-option -p -u @claude-id 2>/dev/null
        return $_rc
    end
    $_claude_cmd $argv
end

set -l _cl_tilt
set -l _claude_cmd
_cl_make_cmd

set -l _git_common (git rev-parse --git-common-dir 2>/dev/null)
if test $status -ne 0
    _cl_detect_tilt (pwd)
    _cl_make_cmd
    _cl_marked_run $argv
    return
end

set -l _groot (path dirname (realpath $_git_common))

function _cl_invoke --no-scope-shadowing
    set -l _dir $argv[1]
    set -l _rest $argv[2..]

    # If no extra args, check for a pending subagent prompt
    if test (count $_rest) -eq 0
        set -l _prompts_dir $_dir/.claude/subagent-prompts
        set -l _pending
        if test -d $_prompts_dir
            for f in $_prompts_dir/*
                test -f $f; and set -a _pending $f
            end
        end
        if test (count $_pending) -eq 1
            set -l _pname (basename $_pending[1] .md)
            _cl_marked_run --name (string join ': ' (basename $_dir) $_pname) "@$_pending[1]"
            rm -f $_pending[1]
            return
        else if test (count $_pending) -gt 1
            echo "cl: multiple pending prompts in $_prompts_dir:"
            for f in $_pending
                echo "  "(basename $f .md)
            end
            echo "run manually: claude (cat $_prompts_dir/<name>.md)"
            return 1
        end
    end

    if set -q _flag_attach; and test -f $_dir/.claude/session; and not string match -q -- '--resume*' $_rest
        _cl_marked_run --resume (string trim <$_dir/.claude/session) $_rest
    else
        _cl_marked_run $_rest
    end
end

# Mode 1: cl . — scope to current worktree only
if test (count $argv) -ge 1; and test "$argv[1]" = .
    _cl_detect_tilt (pwd)
    _cl_make_cmd
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
        _cl_detect_tilt $_target
        _cl_make_cmd
        _cl_invoke $_target $argv[3..]
        return
    end
end

# Mode 3: cl <branch> — single non-flag arg treated as branch in current repo
if test (count $argv) -eq 1; and not string match -q -- '-*' "$argv[1]"
    set -l _candidate $_groot/$argv[1]
    if test -d $_candidate; and test -e $_candidate/.git
        cd $_candidate
        _cl_detect_tilt $_candidate
        _cl_make_cmd
        _cl_invoke $_candidate
        return
    end
end

# Mode 4 (default): add all sibling worktrees as --add-dir for claude AND
# grant safehouse RW on the entire repo tree ($_groot) — bare .git/, every
# sibling, and any not-yet-created sibling. This is what enables in-session
# `c <branch>` / `prepare-subagent`: `git worktree add` needs writes on the
# repo parent (mkdir) and bare .git/ (worktree + ref registration). Scoped
# modes (cl ., cl <branch>, cl <repo> <branch>) deliberately keep the
# narrower default grant and so can't create new worktrees.
set -l _add_dirs
set -l _siblings
for dir in $_groot/*/
    set dir (string trim --right --chars=/ $dir)
    if test -e $dir/.git; and test $dir != (pwd)
        set _add_dirs $_add_dirs --add-dir $dir
        set -a _siblings $dir
    end
end

_cl_detect_tilt (pwd) $_siblings
_cl_make_cmd $_groot

_cl_invoke (pwd) $_add_dirs $argv
