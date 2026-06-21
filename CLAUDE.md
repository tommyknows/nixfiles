# CLAUDE.md - Working with this Nix Configuration Repository

## Overview

macOS (darwin, aarch64) system configuration using Nix flakes, nix-darwin, and
home-manager. Manages two hosts: `work` and `private`. Heavy CLI focus: fish,
vim, tmux, alacritty.

**Repository location:** `~/Documents/nixfiles/main`

## Essential Commands

```bash
# Rebuild and switch (or use the `rebuild` fish abbreviation)
rebuild
# expands to:
sudo nix run nix-darwin -- switch --flake ~/Documents/nixfiles/main\#<host>

# Format nix files
alejandra .
```

## Project Structure

```
flake.nix                 # Hosts, overlays, inputs
darwin/                   # macOS system preferences
hosts/
  system.nix              # Imports darwin configs
  user.nix                # Imports packages + programs
  work/user.nix           # Adds grpcurl, pnpm, work signing key
  private/user.nix        # Adds yt-dlp, vlc-bin, private signing key
packages/default.nix      # All packages
programs/                 # fish, vim, tmux, git, alacritty, go, etc.
work/                     # Work-specific config (loaded conditionally)
  default.nix             # Git email, ic CLI, WORK_GITHUB_USER, Go private modules
  functions/              # Work-specific fish functions
sfx/                      # good.ogg / bad.ogg for boop/sfx functions
```

## Key Architecture Patterns

### Flake Inputs

- `nixpkgs`: nixpkgs-25.11-darwin
- `unstable`: nixos-unstable (fish, gopls, golangci-lint, claude-code, zed, etc.)
- `ic`: infracost internal CLI, built from source (work host only)

### Work Toggle

Work config is conditionally loaded via `extraSpecialArgs`:

```nix
extraSpecialArgs = {work_toggle = "enabled";};  # or "disabled"
```

`programs/default.nix` appends `work/default.nix` when enabled. This controls
git email/key, WORK_GITHUB_USER, Go private modules, and work fish functions.

## Worktree / Workspace Workflow (Critical)

**All branch switching uses per-branch directories.** `c`/`w`/`bd` **dispatch per
repo** (via the git-free `repo_root` helper): a jj repo (it has a `.jj/repo` store at
the root) uses jj workspaces; a plain git repo uses git worktrees.

- **New repos are jj-native.** `clone` (and `w` cloning a fresh repo) uses
  `jj git clone` → **no `.git` at all**, just a bare `.jj` store at the root. jj does
  GitHub fetch/push directly; no git layer.
- **Existing git repos** stay git until you explicitly run `jj-init`, which converts
  them in place to a **hybrid** layout (bare `.git` kept alongside the new bare `.jj`).
  git is a **transitional** fallback there, not permanent.

```
new (jj-native)              existing → after jj-init (hybrid)
repo/                        repo/
├── .jj/    bare jj store    ├── .git/   bare git store (transitional fallback)
├── main/   jj workspace     ├── .jj/    bare jj store
└── feat/   jj workspace     ├── main/   jj workspace
                             └── feat/   jj workspace
```

In both, the bare `.jj` store sits at the root with its default workspace *forgotten*,
so the root never snapshots stray files, and every dir is a jj workspace.

### Key Commands (dispatching — un-prefixed)

- `jj-init` — **explicitly convert** an existing git repo to jj (hybrid; keeps `.git`).
  All-or-nothing: aborts untouched if any worktree is dirty. Not needed for new clones
  (already native).
- `c [NAME [BASE]]` — create/switch. jj repo: a jj workspace off the current `@`
  (falls back to `trunk()`), bookmark named after the branch (for PRs) + `.claude` +
  symlinks; `-o`/`origin/NAME` checks out a remote branch. git repo: a git worktree.
  Existing dir → switch.
- `w [PROJECT] [BRANCH]` — same, for work repos in `~/Documents/work` (also parses
  GitHub PR/tree/blob URLs). Fresh clones are jj-native.
- `bd [-r] [NAME]` — tear down the current/named workspace/worktree, return to the
  default branch. jj repo `-r` integrates the change into the default branch first
  (the old `rbd`); never touches `.jj`/`.git`.

### Key Commands (force git — `g`-prefixed)

- `gc` / `gw` / `gbd [-r]` — git-worktree implementations the dispatchers fall back to
  for plain-git repos; also callable directly to force git worktrees. `gw` clones with
  `clone --git` (plain-git, no jj). Meaningful only in git/hybrid repos, not jj-native.
- `default_branch` — returns `main` or `master` for current repo (git-based; shared).

**Never use `git checkout` / `jj workspace add` directly** — always use `c`/`w`/`bd`
(or the `g`-prefixed force-git variants).

## Important Gotchas

- **Nix is NOT managed by nix-darwin** (`nix.enable = false`) — installed via
  Determinate Systems. Don't try to configure nix itself in the nix files.
- **Unfree packages** must be in `allowed-unfree-packages` in `flake.nix`.
- **Fish functions** that modify shell state (e.g. `cd`) must be fish
  functions, not scripts. Completions live separately in
  `programs/fish/completions/`.
- **Go workspace** is `~/Documents/go` (not `~/go`).
- **SSH agent** uses Secretive: `~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh`
- **Git signing** uses SSH via Secretive, not GPG.
- **Prompt** (bobthefish) is pinned via `fetchFromGitHub` in
  `programs/fish/default.nix` to **our fork** `tommyknows/theme-bobthefish`
  (jj-aware + tuned for the bare-clone/worktree layout, built on upstream's
  `feature/moar-perf`). To update: in the fork's `master` worktree reset to new
  upstream, reapply the jj + worktree-display customizations, push, then bump
  `rev` + `sha256` here. A separate `conf.d/zzz-bobthefish-load.fish` eagerly
  sources `${bobthefishSrc}/functions/*.fish` — bobthefish groups helpers into
  files named after a *different* function, so home-manager's lazy autoload-by-
  name misses them and they error when called. (Don't try to do this by adding a
  `conf.d/plugin-bobthefish.fish` entry — home-manager generates a file by that
  exact name for the plugin and silently shadows yours; hence the unique name.)
- When adding new files, they need to be added to git staging (`git add`) to be picked up by a rebuild.

## Initial Setup (New Machine)

1. Install Nix (Determinate Systems)
2. Clone to `~/Documents/nixfiles/main`
3. `sudo nix run nix-darwin -- switch --flake ~/Documents/nixfiles/main#work`
4. Install Orbstack manually
5. `set -Ux GITHUB_TOKEN "your-token"`
