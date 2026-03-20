Spawn a subagent in a worktree via the `spawn-subagent` Fish function, which handles backgrounding, session capture, and OAuth auth automatically.

Arguments: $ARGUMENTS

Parse $ARGUMENTS as: `<worktree-path> <prompt>` — first whitespace-delimited token is the absolute worktree path, everything after the first space is the prompt text.

Use the Write tool to save the prompt to a unique file under `<worktree-path>/.claude/subagent-prompts/`, then pass it via `string collect` to avoid shell quoting issues. Generate a short unique suffix (e.g. 6 random alphanumeric characters) for the filename.

1. Write the prompt using the Write tool to: `<worktree-path>/.claude/subagent-prompts/<unique-suffix>.txt`
2. Make a single Bash tool call:

```bash
fish -c 'spawn-subagent <worktree-path> (cat <prompt-file> | string collect)'
```

The function prints the session ID, attach hint, and log path. Pass these through to the user as-is.
