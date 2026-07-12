if test (count $argv) -lt 2
    echo "usage: prepare-subagent <worktree-path> <prompt-filename>" >&2
    return 1
end

set -l worktree_path (realpath $argv[1])
set -l prompt_filename $argv[2]

if not test -d $worktree_path
    echo "prepare-subagent: worktree path does not exist: $worktree_path" >&2
    return 1
end

set -l prompt_file $worktree_path/.claude/subagent-prompts/$prompt_filename

if not test -f $prompt_file
    echo "prepare-subagent: prompt file not found: $prompt_file" >&2
    return 1
end

# Determine the cl command based on repo location
set -l branch (basename $worktree_path)
set -l repo_dir (dirname $worktree_path)
set -l repo_name (basename $repo_dir)

set -l cl_cmd
if test $repo_dir = /Users/ramon/Documents/nixfiles
    set cl_cmd "cl nixfiles $branch"
else if string match -q '/Users/ramon/Documents/work/*' $repo_dir
    set cl_cmd "cl $repo_name $branch"
else
    set cl_cmd "cl $branch"
end

echo "run in new terminal: $cl_cmd"
