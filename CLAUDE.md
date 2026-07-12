# CLAUDE.md - Working with this Nix Configuration Repository

## Overview

Nix flakes config using nix-darwin + home-manager for two macOS hosts (`work`,
`private`, aarch64) and a NixOS homeserver (`server`, x86_64). Heavy CLI focus:
fish, vim, tmux, alacritty. Two module libraries — `system/` (OS/nix-darwin) and
`home/` (home-manager) — composed by thin per-host dirs under `hosts/`.

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
flake.nix                 # inputs; darwin hosts (genAttrs) + nixosConfigurations (server, server-vm)
system/                   # system layer (nix-darwin / NixOS)
  nixpkgs.nix             #   shared nixpkgs.config (unfree allowance) — imported by both below
  darwin/                 #   macOS system: defaults, determinate, overlays, fonts
  nixos.nix               #   generic NixOS base: admin user, sshd, locale, nix settings
hosts/                    # thin per-host composition (pick system layer + home profiles + machine bits)
  private/                #   system.nix (dock) + home.nix (client + private identity + signing key)
  work/                   #   system.nix + home.nix (client + work identity + signing key)
  server/                 #   NixOS homeserver — base + service modules + home.nix
home/                     # home-manager layer
  default.nix             #   shared base: shell/editor/VCS + core CLI packages
  client.nix  server.nix  #   platform profiles (macOS / NixOS)
  private.nix  work/       #   identity profiles (work/ builds infracost CLIs, sets work git identity)
  fish/ git/ jujutsu/ vim/ tmux/ alacritty.nix autokbisw.nix claude/
packages/emby-server/     # custom Emby .deb repack (server)
secrets/                  # sops-encrypted (age); .sops.yaml + server.yaml
sfx/                      # good.ogg / bad.ogg for boop/sfx functions
```

Two system layers (`system/darwin`, `system/nixos`) share `system/nixpkgs.nix`;
hosts compose one of them plus home profiles. The server's layout constants +
`appDir` helper live in `hosts/server/paths.nix`, injected to every server
module as the arg `paths` via `_module.args`. Server *service* config
(zfs/media/nginx/…) is co-located in `hosts/server/`; the generic NixOS base is
in `system/nixos.nix`.

## Key Architecture Patterns

### Flake Inputs

- `nixpkgs`: nixpkgs-26.05-darwin (the Macs)
- `nixos`: nixos-26.05 (the server)
- `unstable`: nixos-unstable (fish, gopls, golangci-lint, claude-code, zed, etc.)
- `sops-nix`: server secrets (age)
- `determinate`: Determinate Nix nix-darwin module
- `ic` / `infracost_cli` / `cloud-data` / `internal-skills`: infracost sources,
  built/used by the work identity profile (work host only)

### Host composition & the work identity

Each `hosts/<host>/` is thin: `system.nix` (per-host system bits) + `home.nix`
that imports the shared home profiles. macOS hosts compose
`home/client.nix` + an identity profile:

- `private` → `home/private.nix`
- `work` → `home/work/` (infracost CLIs, work git/jj identity for
  `~/Documents/work`, work env + fish functions, work Claude skills)

Work's private flake inputs are threaded only for that host, via
`home-manager.extraSpecialArgs` gated on `hostname == "work"` in `flake.nix`
(there is no separate toggle). The server composes `home/server.nix`.

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

- **Nix core is installed/managed by Determinate**, not nix-darwin
  (`nix.enable = false` in `system/darwin/default.nix`) — so nix-darwin's `nix.settings`
  / `nix.extraOptions` are inert. Configure Nix declaratively through the
  **Determinate nix-darwin module** instead (`inputs.determinate.darwinModules.default`):
  `determinateNix.customSettings` is a freeform attrset written to
  `/etc/nix/nix.custom.conf`, and dedicated options cover things the module
  reserves — e.g. the native Linux builder is
  `determinateNix.determinateNixd.builder.state = "enabled"` (NOT `external-builders`
  in customSettings; that's on the module's reserved-settings denylist and will
  fail the build). Don't hand-edit `/etc/nix/*` or run `launchctl kickstart` for
  config that belongs here.
- **Unfree packages** must be added to the allow-list in `system/nixpkgs.nix`
  (shared by macOS and NixOS; the list is the union across hosts).
- **Fish functions** that modify shell state (e.g. `cd`) must be fish
  functions, not scripts. Completions live separately in
  `home/fish/completions/`.
- **Go workspace** is `~/Documents/go` (not `~/go`).
- **SSH agent** uses Secretive: `~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh`
- **Git signing** uses SSH via Secretive, not GPG.
- **Prompt** (bobthefish) is pinned via `fetchFromGitHub` in
  `home/fish/default.nix` to **our fork** `tommyknows/theme-bobthefish`
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
