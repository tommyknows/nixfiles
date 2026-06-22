# Development Environment

> **Maintenance note**: Update this file freely — and without being asked — whenever you encounter information that is missing, wrong, or outdated.

## Repository layout

- Work repos: `~/Documents/work/<repo>/`
- Nixfiles: `~/Documents/nixfiles/`

All repos use a bare-clone + per-branch-directory layout: branches are checked
out as sibling directories under the repo root. Repos are migrating from git to
**Jujutsu (jj)** incrementally, **per repo** — so at any time some are plain git
and some are jj. **Tell them apart by a `.jj/` directory at the repo root.**

```
plain git (not migrated)        jj-migrated (hybrid)
~/Documents/work/replay/        ~/Documents/work/replay/
  .git/   ← bare git repo         .git/   ← bare git store (transitional)
  master/ ← git worktree          .jj/    ← bare jj store (default ws forgotten)
  feat_thing/ ← git worktree      master/ ← jj workspace (.jj, no .git)
                                  feat_thing/ ← jj workspace
```

(slashes in branch names → underscores in dir names). A jj **workspace** is
*non-colocated*: it has `.jj` but **no `.git`** of its own.

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

## Creating worktrees / workspaces

Always use `c <branch> [base]` — never `git worktree add` or `jj workspace add`
directly. `c`/`w`/`bd` **dispatch automatically**: in a jj repo they manage jj
workspaces; in a plain-git repo, git worktrees. (Their git implementations are
also exposed as `gc`/`gw`/`gbd` to force git.) Convert an existing git repo to jj
with `jj-init` (whole-repo, all-or-nothing if any worktree is dirty).

## VCS operations — use the repo's actual VCS

In a **jj repo** (has `.jj/`), use **`jj`, never `git`**, for VCS work. Its
workspaces are non-colocated, so `git status`/`git diff`/`git commit` there read
the bare repo, not your working copy — they silently mislead or fail. Map:

- inspect: `jj st`, `jj log`, `jj diff`
- record: `jj describe -m` (set message on `@`), `jj commit -m` (describe + start a new change), `jj new` (new empty change)
- amend mid-stack: `jj edit <change>` then just edit files; or `jj squash [--into <change>]`; or `jj absorb` (auto-distribute working-copy hunks into the ancestors that last touched them)
- remote: `jj git fetch` (≈ pull), `jj git push --bookmark <name>` (≈ push). A **bookmark** is jj's equivalent of a branch
- resolve conflicts: `jj resolve` (uses mergiraf; non-blocking — conflicts don't stop a merge/rebase)

In a **plain-git repo** (no `.jj/`), use `git` as before.

## Stacked branch workflow

**jj repos — restacking is automatic.** Each workspace's change sits on its base;
edit any change in place (`jj edit <change>` then edit files, or `jj squash` /
`jj absorb` from the working copy) and **descendants rebase automatically**
(`auto-update-stale` is on) — no manual downstream cascade. `bd -r` integrates the
current workspace's change into the default branch before teardown. To restack
onto a moved base explicitly: `jj rebase -d <base>`.

**plain-git repos** (`master` ← `wt-1` ← `wt-2`): each branch owns its commits;
amend in the worktree that created the commit, then cascade downstream.
- Preferred — `git absorb`: stage changes, then `git absorb --and-rebase --base <upstream-branch>`.
- Manual: `git rebase -i master` in `wt-1`; then in `wt-2` `git rebase wt-1` (`--onto` to skip duplicates); repeat downstream.

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

## kubectl

- Always pass `--context <name>` to every `kubectl` invocation. Discover available contexts with `kubectl config get-contexts`.
- Always pass `--namespace <ns>` for namespaced resources; never assume `default`.

These rules override any kubectl examples in skills or commands that show `KUBECONFIG=…` or `kubectl config use-context`.

## Worktree path translation

Skill and command examples may reference work-repo paths as if `$CODE_DIR/<repo>/` (i.e. `~/Documents/work/<repo>/`) were a working tree. It's a bare clone — actual files live under `$CODE_DIR/<repo>/<worktree>/...`. The worktree segment **always comes immediately after the repo name**, before any further subpath. Defaults: `dashboard` and `infra` → `master`; `runner` and `technical-docs` → `main`. Use a different worktree only when context says so.

Examples:
- `$CODE_DIR/dashboard/api/prisma/schema.prisma` → `$CODE_DIR/dashboard/master/api/prisma/schema.prisma`
- `$CODE_DIR/infra/prod/kubeconfig_prod` → `$CODE_DIR/infra/master/prod/kubeconfig_prod` (`prod` is a subdir, not a worktree)
- `cd $CODE_DIR/runner` → `cd $CODE_DIR/runner/main`

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
