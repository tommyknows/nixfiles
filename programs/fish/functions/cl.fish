argparse --ignore-unknown a/attach n/no-sandbox server 'wt=+' -- $argv
or return

set -l _claude_binary ~/Downloads/claude

# --wt=<dir> (repeatable): grant the sandbox RW access to a worktree. The
# worktree's bare store(s) at the repo root are added too — otherwise VCS
# writes fail even though the working copy is writable. Both layouts keep the
# store at the root: jj's shared object store + change metadata in <root>/.jj
# (jj workspaces are non-colocated, so the store is NOT under the workspace
# dir), and git's bare store in <root>/.git. Without the .jj grant,
# `jj commit`/`describe`/`new` fail writing to <root>/.jj/repo/store/**
# ("Operation not permitted") even though `jj st` snapshots fine (that only
# touches <workspace>/.jj/working_copy, which is inside the granted dir). This
# mirrors the pwd-repo _repo_jj/_repo_git grant in _cl_make_cmd.
if set -q _flag_wt
    set -l _expanded
    for d in $_flag_wt
        # Fish doesn't expand `~/` mid-word (e.g. in --wt=~/foo), so do it here.
        set d (string replace -r '^~/' "$HOME/" -- $d)
        test -e $d; or continue
        set d (realpath $d)
        set -a _expanded $d
        # Grant the bare store(s) at <d>'s repo root (jj and/or git).
        set -l _wrr (repo_root $d 2>/dev/null)
        if test -n "$_wrr"
            test -d $_wrr/.jj; and set -a _expanded $_wrr/.jj
            test -d $_wrr/.git; and set -a _expanded $_wrr/.git
        end
        # Fallback for linked git worktrees whose bare store isn't an ancestor
        # dir (repo_root can't find it by walking up): git's own common-dir pointer.
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
        set _claude_cmd $_claude_binary
        return
    end
    # ~/.config/jj is RW so in-session `c` can write jj's per-repo "secure config"
    # (jj 0.42+ stores it under ~/.config/jj/repos/); otherwise jj errors on every call.
    # The repo's own .jj store (at the repo root) is RW too, so jj can snapshot the
    # working copy even in the scoped modes that don't grant the whole tree.
    # jj only has a git backend; where its object store lives depends on how the repo
    # was made. A native `jj git clone` keeps it INSIDE .jj (.jj/repo/store/git), which
    # the .jj grant above already covers. But a `jj-init`-converted repo keeps the
    # original EXTERNAL bare .git at the root (git_target -> ../../../.git) and writes
    # objects there — .jj alone isn't enough. So also grant the bare .git RW when
    # present, or `jj commit`/`new`/`describe` fail writing the new commit object
    # ("Operation not permitted .../.git/objects") even though `jj st` works
    # (snapshotting reuses already-written objects). Plain-git repos likewise keep
    # their bare store in .git at the root, so this covers them too.
    set -l _repo_jj
    set -l _repo_git
    set -l _rr (repo_root 2>/dev/null)
    test -n "$_rr"; and test -d $_rr/.jj; and set _repo_jj $_rr/.jj
    test -n "$_rr"; and test -d $_rr/.git; and set _repo_git $_rr/.git
    set -l _rw $HOME/Documents/go $HOME/Library/Caches/go-build $HOME/.config/jj $_repo_jj $_repo_git $argv $_flag_wt
    set -l _safehouse_args \
        --add-dirs=(string join : $_rw) \
        --add-dirs-ro=$HOME/Documents/work:$HOME/Documents/nixfiles \
        --append-profile=$HOME/.config/agent-safehouse/local-overrides.sb \
        --env-pass=GITHUB_TOKEN \
        --env-pass=TEST_DB_URL \
        --env-pass=TEST_LOCALSTACK_ENDPOINT \
        --env-pass=TMUX \
        --env-pass=TMUX_PANE
    # --server: append the server-workflow profile (determinate-nixd control
    # socket) on top of local-overrides.sb. Everything else the Nix server
    # workflow needs (nix CLI exec, /etc/nix, nix-daemon socket, egress,
    # localhost hostfwd binds for the server-vm) is already in the base profile;
    # grant the server config dir itself with --wt=~/Documents/private/server/...
    if set -q _flag_server
        set _safehouse_args $_safehouse_args --append-profile=$HOME/.config/agent-safehouse/server-overrides.sb
    end
    set -l _env_prefix
    if test -n "$_cl_tilt"
        set _safehouse_args $_safehouse_args --enable=docker --env-pass=KUBECONFIG
        set _env_prefix env KUBECONFIG=$HOME/.kube/configs/tilt
        echo "cl: Tiltfile detected — enabling docker socket + scoped kubeconfig (~/.kube/configs/tilt)" >&2
    end
    set _claude_cmd $_env_prefix safehouse $_safehouse_args -- $_claude_binary --dangerously-skip-permissions
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
if set -q _flag_server; and not set -q _flag_no_sandbox
    echo "cl: --server — enabling determinate-nixd control socket" >&2
end
_cl_make_cmd

set -l _groot (repo_root 2>/dev/null)
if test $status -ne 0
    _cl_detect_tilt (pwd)
    _cl_make_cmd
    _cl_marked_run $argv
    return
end

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
        if not test -d $_target; or begin; not test -e $_target/.git; and not test -e $_target/.jj; end
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
    if test -d $_candidate; and begin; test -e $_candidate/.git; or test -e $_candidate/.jj; end
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
    if begin; test -e $dir/.git; or test -e $dir/.jj; end; and test $dir != (pwd)
        set _add_dirs $_add_dirs --add-dir $dir
        set -a _siblings $dir
    end
end

_cl_detect_tilt (pwd) $_siblings
_cl_make_cmd $_groot

_cl_invoke (pwd) $_add_dirs $argv
