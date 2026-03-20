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
- `nix-ai-tools`: numtide/nix-ai-tools (crush)
- `ic`: infracost internal CLI, built from source (work host only)

### Work Toggle

Work config is conditionally loaded via `extraSpecialArgs`:

```nix
extraSpecialArgs = {work_toggle = "enabled";};  # or "disabled"
```

`programs/default.nix` appends `work/default.nix` when enabled. This controls
git email/key, WORK_GITHUB_USER, Go private modules, and work fish functions.

## Git Worktree Workflow (Critical)

**All branch switching uses worktrees** — each branch is its own directory.

```
repo/
├── .git/           # bare git dir (never checkout here)
├── main/           # main branch
└── my-feature/     # feature branch
```

### Key Commands

- `c [BRANCH]` — create/switch worktree branch in current repo. Also creates
  `.claude` dir and symlinks shared local configs between worktrees.
- `w [PROJECT] [BRANCH]` — same but for work repos in `~/Documents/work`
- `bd [BRANCH]` — delete current (or named) worktree, return to default branch
- `rbd` — rebase default branch onto current, then delete worktree
- `default_branch` — returns `main` or `master` for current repo

**Never use `git checkout` directly** — always use `c` or `w`.

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
- When adding new files, they need to be added to git staging (`git add`) to be picked up by a rebuild.

## Initial Setup (New Machine)

1. Install Nix (Determinate Systems)
2. Clone to `~/Documents/nixfiles/main`
3. `sudo nix run nix-darwin -- switch --flake ~/Documents/nixfiles/main#work`
4. Install Orbstack manually
5. `set -Ux GITHUB_TOKEN "your-token"`
