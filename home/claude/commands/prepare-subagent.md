Prepare a subagent prompt so the user can start it in a new terminal window.

Arguments: $ARGUMENTS

Parse $ARGUMENTS as: `<worktree-path> <prompt>` — first whitespace-delimited token is the absolute worktree path, everything after is the prompt text.

1. Determine the repo and whether it's a work repo (under `~/Documents/work/`):

   - **Work repo**: create a new branch by running `fish -c 'w <repo> <branch-name>'` in a Bash call. The worktree path is `~/Documents/work/<repo>/<branch-name>` (replace `/` with `_` in the branch name). Use that path for steps 2–3.
   - **Other repo** (e.g. nixfiles at `~/Documents/nixfiles/main`): use the provided worktree path as-is.

   Choose a short descriptive branch name that reflects the task (e.g. `feat-auth`).
   If `w` has run successfully, you can assume that the branch & path exist.

2. Write the prompt using the Write tool to: `<worktree-path>/.claude/subagent-prompts/<descriptive-name>.md`

   - Use a short descriptive name (not random) that reflects the task, e.g. `implement-auth.md`

3. Make a single Bash tool call:

```bash
fish -c 'prepare-subagent <worktree-path> <descriptive-name>.md'
```

4. Pass the printed `cl` command through to the user exactly as-is, e.g.:
   > Run in a new terminal: `cl replay feat-auth`
