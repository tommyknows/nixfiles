set -l worktree_path (realpath $argv[1])
set -l prompt $argv[2..]

if test (count $prompt) -eq 0
    echo "usage: spawn-subagent <worktree-path> <prompt...>" >&2
    return 1
end

if not test -d $worktree_path
    echo "spawn-subagent: worktree path does not exist: $worktree_path" >&2
    return 1
end

set -l dirname (basename $worktree_path)
set -l logfile /tmp/$dirname.jsonl

set -l _cwd (pwd)
cd $worktree_path
env -u ANTHROPIC_API_KEY claude -p $prompt --output-format stream-json --verbose > $logfile 2>&1 &
set -l claude_pid $last_pid
cd $_cwd

# Poll until session_id appears in the logfile
set -l session_id ""
while test -z "$session_id"
    set session_id (grep -o '"session_id":"[^"]*"' $logfile 2>/dev/null | head -1 | grep -o '"[^"]*"$' | string trim --chars='"')
    if test -z "$session_id"
        sleep 0.05
    end
end

mkdir -p $worktree_path/.claude
echo $session_id > $worktree_path/.claude/session
echo $claude_pid > $worktree_path/.claude/pid

echo "session: $session_id"
echo "attach:  cl $dirname -a"
echo "log:     $logfile"
