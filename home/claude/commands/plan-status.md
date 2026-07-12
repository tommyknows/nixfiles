Show the status of stacked branch plans for this repo.

Plan filter: $ARGUMENTS (optional — if provided, show only the matching plan; otherwise show all)

## Steps

**1. Find plans**:
- Locate `<groot>/.claude/plans/` where `groot` is the parent of the current worktree
- List plan directories; if $ARGUMENTS is given, filter to the matching plan name
- If no plans are found, say so and exit

**2. For each plan, read `plan.md` and check each step**:

- **Worktree**: does it exist? (`git worktree list`)
- **Commits**: what has landed on this branch over its base?
  (`git log <base>..<branch> --oneline`)
- **PR**: is there an open PR?
  (`gh pr list --head <branch> --json number,title,url,state`)
- **Needs rebase**: does the base branch have commits not yet in this branch?
  (`git log <branch>..<base> --oneline`)

**3. Report**, grouped by plan:

```
Plan: auth-flow
  ✓ step-1/add-jwt-middleware     — merged (PR #42)
  → step-2/add-rate-limiting      — 3 commits, PR #44 open
  ○ step-3/add-audit-logging      — not started
```

Flag any branch that needs rebasing with a warning.
