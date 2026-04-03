# Development Environment

> **Maintenance note**: Update this file freely — and without being asked — whenever you encounter information that is missing, wrong, or outdated.

## Repository layout

- Work repos: `~/Documents/work/<repo>/`
- Nixfiles: `~/Documents/nixfiles/`

All repos use a bare-clone + worktree layout. Each repo is a bare `.git`; branches are checked out as sibling directories:

```
~/Documents/work/replay/
  .git/         ← bare git repo
  master/       ← worktree for branch `master`
  feat_thing/   ← worktree for branch `feat/thing` (slashes → underscores)
```

## Fish commands

| Command                         | Effect                                                                                             |
| ------------------------------- | -------------------------------------------------------------------------------------------------- |
| `c [branch] [base]`             | Create/switch worktree in the **current repo**. No args = switch to default branch.               |
| `w <repo> [branch]`             | Switch to a repo under `~/Documents/work/`, cloning if needed. Accepts GitHub PR URLs.            |
| `bd [branch]`                   | Delete current (or named) worktree, return to default branch.                                     |
| `cl [args]`                     | Global session: run `claude` with every sibling worktree added as `--add-dir`.                    |
| `cl . [args]`                   | Scoped session: current worktree only.                                                             |
| `cl <worktree> [args]`          | Scoped session: named sibling worktree (same repo).                                               |
| `cl <repo> <branch> [args]`     | Scoped session: named worktree in a different repo (`nixfiles` or `~/Documents/work/<repo>`).     |
| `cl ... -a`                     | Any of the above with `-a`: resume the session stored in `<worktree>/.claude/session`.            |

`c` works in any repo. `w` is scoped to `~/Documents/work/`.

## Claude sessions

Sessions for all worktrees of a repo are stored in `~/.claude/projects/<path-with-slashes-as-dashes>/` (e.g. nixfiles → `-Users-ramon-Documents-nixfiles`). Worktree-specific paths are symlinks to that canonical directory, so `--resume` shows full history from any worktree. This is set up automatically by `c` when creating a worktree.

## Creating worktrees

Always use `c <branch> [base]` — never `git worktree add` directly.

## Stacked branch workflow

When working with stacked branches (`master` ← `wt-1` ← `wt-2`), each branch owns its commits. Always amend in the worktree that created the commit, then cascade the rebase downstream.

**Preferred method — `git absorb`**: stage changes and run:

```bash
git absorb --and-rebase --base <upstream-branch>
```

Manual flow for amending a commit in `wt-1`:
1. `git rebase -i master` in the `wt-1` worktree
2. In `wt-2`: `git rebase wt-1` (use `--onto` to skip duplicates if needed)
3. Repeat downstream

## Spawning subagents

To spawn a subagent, write the prompt to a file and call `prepare-subagent`. Use the `/prepare-subagent` slash command which handles this automatically.

The prompt file must live in `<worktree>/.claude/subagent-prompts/`. `prepare-subagent` validates the file and prints the `cl` command the user should run in a new terminal window. When they run it, `cl` detects the pending prompt and starts an interactive claude session automatically.

The `-a` flag resumes a completed session: `cl <branch> -a` (same repo) or `cl <repo> <branch> -a`.

## Scripting conventions

- **Scripts** (CI, automation): Bash
- **Shell functions / interactive use**: Fish (default shell)
- **Never write ad-hoc Python scripts** — use CLI tooling instead.
- **Prefer CLI tools** for data wrangling and code manipulation: `jq`, `yq`, `goimports`, `gomvpkg`, etc.
- **If a CLI tool isn't available**, run it via a temporary nix shell rather than reimplementing it: `nix-shell -p <pkgName> --run '<cmd>'`.

## Global config changes

Changes to shell functions, packages, or system settings belong in the nixfiles repo (`~/Documents/nixfiles/main`), not applied ad-hoc. Spawn a subagent there and rebuild with `rebuild` (must be run as a Fish function, not in Bash).

## Work repos

| Repo                | Description                       |
| ------------------- | --------------------------------- |
| `replay`            | GitHub webhook reverse proxy (Go) |
| `infracost`         | Infracost CLI (Go)                |
| `dashboard`         | Infracost dashboard (Node/React)  |
| `cloud-pricing-api` | Cloud pricing API (Node)          |
| `ic`                | Internal CLI tooling              |
| `infra`             | Terraform infrastructure          |
| `runner`            | CI runner service                 |
