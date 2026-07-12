Plan a feature as a stacked branch sequence, then create the branches and worktrees.

Goal: $ARGUMENTS

## Steps

**1. Gather context** (do this before asking the user anything):
- Read the repo's CLAUDE.md files for project context
- Run `git log --oneline -20` and `git branch` to understand current state
- If no goal was provided in $ARGUMENTS, ask the user what they want to build

**2. Propose a plan**:
- Break the goal into sequential steps, each a small, independently-reviewable PR
- Step 1 bases off the current branch; each subsequent step bases off the previous
- Use kebab-case branch names; if the repo uses a prefix convention (e.g. `feat/`), follow it
- Present the steps clearly (branch name + one-line description + base) and ask for confirmation before creating anything

**3. Once confirmed, create all branches and worktrees immediately**:

Create each branch in sequence, branching each off the previous:

```
fish -c "c <step-1-branch>"         # branches off current HEAD
fish -c "c <step-2-branch> <step-1-branch>"
fish -c "c <step-3-branch> <step-2-branch>"
...
```

`c` handles worktree creation, directory naming (slashes → underscores), Claude session
symlinking, and `.claude/` directory creation automatically.

Derive a short kebab-case plan name from the goal (e.g. `auth-flow`). All plan files live
under `<groot>/.claude/plans/<plan-name>/`, keeping concurrent independent plans separate.

Write a context file for **every step** to `<groot>/.claude/plans/<plan-name>/step-N.md`,
each containing:
- The overall plan goal
- The full branch sequence for this plan, in order (e.g. `master ← step-1 ← step-2 ← step-3`)
- Which step this is and what it must accomplish
- What the previous step delivered (for step > 1)
- What the next step will build on top of (for step < last)

Copy each step's context into its worktree at `<worktree_path>/.claude/context.md`. Include
a comment at the top noting which plan and step this is, so it's easy to trace back.

The worktree path is `<groot>/<dir_name>` where `groot` is the parent of the current worktree
and `dir_name` is the branch name with `/` replaced by `_`.

**4. Write the plan file** at `<groot>/.claude/plans/<plan-name>/plan.md`:
```markdown
# Plan: <goal>
Base: <base-branch>
Created: <date>

## Branch sequence
`<base>` ← `<step-1-branch>` ← `<step-2-branch>` ← ...

## Execution
- Use one subagent per worktree when implementing steps. Each subagent must be instructed to
  only edit files inside its designated worktree path.
- **Rebase cascade**: check for upstream divergence at the start and end of every step. After
  any change to step N (or if the user amended upstream out-of-band), rebase every downstream
  step in sequence (N+1, N+2, …). Check for duplicate commits first; use `git rebase --onto`
  to skip them. Run tests after each rebase. Pause only when a conflict requires judgment.

## Steps
### 1. `<branch>` — <description>
Status: pending

### 2. `<branch>` — <description>
Status: pending
...
```

After setup, print a summary of what was created and how to navigate between steps (`c <branch>`).

## Executing a plan via subagents

When asked to implement one or more steps (rather than just plan), use subagents — one per
worktree — so each step runs in its correct branch context.

Spawn each subagent via Bash from its worktree directory (not via the Agent tool) so it gets
the correct LSP workspace:

```bash
cd <worktree_path>
claude -p "<prompt>" --output-format json > /tmp/step-N.json
jq -r '.session_id' /tmp/step-N.json > <worktree_path>/.claude/session
```

This lets the user attach to the subagent session later by running `cl .` or `cl <worktree>`
from any terminal — `cl` will auto-resume if `.claude/session` exists.

Each subagent prompt must include:
- The absolute path to its worktree
- An explicit instruction: **only edit files inside `<worktree_path>`. Do not read or modify
  files in any other worktree or directory.**
- The step context (contents of `step-N.md`)

**At the start and end of every step**, check whether any upstream branch has diverged from
what downstream branches were based on — the user may have amended commits out-of-band:

```bash
git log <upstream>..<branch> --oneline   # commits genuinely on this branch
git log <branch>..<upstream> --oneline   # upstream commits not yet in this branch (needs rebase)
```

**Rebase cascade rule**: whenever upstream divergence is detected, or after any subagent
changes step N, immediately rebase every downstream step in order (N+1, N+2, …):

1. Run `git log <upstream>..<branch> --oneline` to identify which commits are genuinely new.
2. If any commits are duplicates of upstream work, use `--onto` to skip them:
   `git rebase --onto <new-base> <last-commit-to-skip> <branch>`
3. Only use plain `git rebase <upstream>` when there are no duplicate commits.
4. **After every rebase, run the repo's tests** to confirm nothing broke before continuing.

Pause and ask the user only if a conflict requires judgment. Never independently apply a fix
to branch N+1 that belongs on branch N — this creates duplicates that cause cascade conflicts.

Keep the `plan.md` branch sequence as the authoritative order for determining which steps are
downstream of which.
