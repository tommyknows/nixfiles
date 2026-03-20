set -l worktree_dir $argv[1]
set -l extra_args $argv[2..]
set -l dirname (basename $worktree_dir)
set -l pid_file $worktree_dir/.claude/pid
set -l session_file $worktree_dir/.claude/session
set -l logfile /tmp/$dirname.jsonl

if not test -f $session_file
    echo "subagent-attach: no session found at $session_file" >&2
    return 1
end

set -l session_id (string trim <$session_file)

if test -f $pid_file
    set -l pid (string trim <$pid_file)
    if kill -0 $pid 2>/dev/null
        echo "Agent running (PID $pid) — streaming output. Ctrl-C to stop watching." >&2
    end
end

# Stream with a single jq process; jq calls halt on the result event so the
# pipeline exits cleanly. Ctrl-C also exits the pipeline; either way we land
# below to decide what to do next.
if test -f $logfile
    tail -n +1 -f $logfile 2>/dev/null | jq --unbuffered -rj '
      if .type == "assistant" then
        ((.message.content // [])[] | select(.type == "text") | .text)
      elif .type == "result" then
        ("\n\n[done: " + (.subtype // "unknown") + "]\n"), halt
      else
        empty
      end
    ' 2>/dev/null
end

# Re-check whether the agent is still alive after streaming stopped.
set -l running_pid ""
if test -f $pid_file
    set running_pid (string trim <$pid_file)
    if not kill -0 $running_pid 2>/dev/null
        set running_pid ""
    end
end

if test -n "$running_pid"
    echo "" >&2
    read -l -P "Agent (PID $running_pid) still running. [i]nterrupt & resume / [q]uit: " choice
    if string match -qi i $choice
        kill $running_pid 2>/dev/null
        sleep 0.3
        exec claude --resume $session_id $extra_args
    end
else
    exec claude --resume $session_id $extra_args
end
