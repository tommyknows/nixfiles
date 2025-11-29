# AGENTS.md - Working with this Nix Configuration Repository

## Overview

This repository contains a complete macOS (Darwin) system configuration using Nix, nix-darwin, and home-manager. It manages system settings, packages, dotfiles, and program configurations for two machines: a work laptop and a private laptop. The configuration is heavily optimized for CLI-based workflows using vim, tmux, fish shell, and alacritty.

**Platform:** macOS (darwin), aarch64 architecture only  
**Package Manager:** Nix with flakes  
**Configuration Manager:** nix-darwin + home-manager

## Essential Commands

### Building and Applying Configuration

```bash
# Rebuild and switch system configuration
darwin-rebuild switch --flake ~/.nixpkgs

# Build without switching (testing)
darwin-rebuild build --flake ~/.nixpkgs

# Build specific host configuration
darwin-rebuild switch --flake ~/.nixpkgs#work-laptop
darwin-rebuild switch --flake ~/.nixpkgs#private-laptop
```

**Note:** The `rebuild` abbreviation is set in fish config: `abbr rebuild "darwin-rebuild switch --flake ~/.nixpkgs"`

### Nix Formatting

```bash
# Format all .nix files (uses alejandra)
alejandra .
```

### Testing Configuration Changes

After modifying any `.nix` files, you must rebuild the configuration. Changes to:
- System settings (darwin/*.nix, hosts/system.nix) require rebuild + restart/logout for some settings
- Programs (programs/**/*.nix) require rebuild, then restart the terminal/program
- Packages (packages/default.nix) require rebuild
- Fish functions (programs/fish/functions/*.fish) are automatically picked up on next shell restart

## Project Structure

```
.
├── flake.nix                 # Main flake configuration, defines hosts and overlays
├── flake.lock                # Locked dependency versions
├── darwin/
│   ├── system.nix           # macOS system preferences and settings
│   ├── user.nix             # User-level macOS configuration
│   ├── autokbisw.nix        # Auto keyboard input source switcher config
│   └── bluesnooze.nix       # Bluesnooze (bluetooth sleep manager) config
├── hosts/
│   ├── system.nix           # Top-level system configuration (imports darwin configs)
│   ├── user.nix             # Top-level user configuration (imports packages + programs)
│   ├── work/
│   │   ├── work.nix         # Work-specific system config
│   │   └── user.nix         # Work-specific user config (git email, functions)
│   └── private/
│       ├── private.nix      # Private machine system config
│       └── user.nix         # Private machine user config
├── packages/
│   └── default.nix          # All system packages (CLI tools, languages, etc.)
├── programs/
│   ├── default.nix          # Program configurations (go, lsd, fzf, ripgrep, ssh)
│   ├── fish/                # Fish shell configuration
│   ├── vim/                 # Vim configuration
│   ├── tmux/                # Tmux configuration
│   ├── git/                 # Git configuration
│   └── alacritty/           # Alacritty terminal configuration
├── work/
│   ├── default.nix          # Work-specific config (git, fish functions)
│   └── functions/           # Work-specific fish functions
└── sfx/                     # Sound effects (good.ogg, bad.ogg) for notify function
```

## Key Architecture Patterns

### Flake Structure

The flake defines two Darwin configurations (`work-laptop` and `private-laptop`), both using:
- Same nixpkgs version (nixpkgs-25.05-darwin)
- Unstable channel for specific packages (gopls, golangci-lint, tailscale, snyk, fish, protobuf, autokbisw, crush)
- Overlay system to pull packages from unstable: defined in `unstablePackages` overlay
- Allowlist for unfree packages: ngrok, slack, terraform, crush

### Module Imports

The configuration uses a hierarchical import structure:
1. `flake.nix` → defines hosts with modules
2. Host-specific files (`hosts/work/work.nix`) → minimal, mostly empty
3. `hosts/system.nix` → imports `darwin/system.nix` and `darwin/user.nix`
4. `hosts/user.nix` → imports `packages/` and `programs/`
5. Program-specific imports use `work_toggle` special arg to conditionally load work configs

### Work Toggle Pattern

Work-specific configurations are conditionally loaded using `extraSpecialArgs`:
```nix
extraSpecialArgs = {work_toggle = "enabled";};  # or "disabled" for private
```

In `programs/default.nix`:
```nix
work = {
  "enabled" = [(import ../work/default.nix)];
  "disabled" = [];
};
imports = [...] ++ (work.${work_toggle} or []);
```

## Git Worktree Workflow (Critical)

**This configuration is built around git worktrees.** Understanding this is essential.

### Core Concept

Instead of checking out branches in the same directory, each branch lives in its own subdirectory:
```
repository/
├── .git/              # Bare git directory
├── main/              # main branch worktree
├── feature-branch/    # feature-branch worktree
└── another-feature/   # another-feature worktree
```

### Primary Commands

#### `w [PROJECT] [BRANCH] [COMMIT]`

Switches to work repositories (`/Users/ramon/Documents/work`):
- `w` - go to work directory
- `w snyk-docker-plugin` - clone if needed, cd to main/master branch
- `w snyk-docker-plugin my-feature` - create/switch to my-feature branch worktree
- `w snyk-docker-plugin my-feature abc123` - checkout my-feature at commit abc123
- `w https://github.com/org/repo/pull/123` - clone repo, checkout PR branch

**Autocompletion:**
- Tab on first arg: lists repos
- Tab on second arg: local branches (prefix `o` for origin branches, `v` for tags)
- Tab on third arg: interactive commit picker (fzf)

**Environment variable:** `WORK_GITHUB_USER` (set to "infracost" for work config)

#### `c [BRANCH] [COMMIT]`

Checkout/switch branches in current repository:
- `c` - switch to default branch (main/master)
- `c my-feature` - create/switch to my-feature branch
- `c my-feature abc123` - checkout my-feature at commit abc123
- `c origin/remote-branch` - track and checkout remote branch locally

**Options:**
- `-j TICKET` or `--jira=TICKET` - store Jira ticket in git notes for the branch

**Autocompletion:** same pattern as `w`

#### `default_branch`

Returns the default branch name (main or master) for the current repository:
```bash
git pull origin (default_branch) --rebase
```

### Related Functions

- `clone OWNER/REPO [PATH]` - clones repo with worktree structure
- `git-pick-commit` - interactive commit picker with fzf
- `gitclean` - likely removes old worktrees (check implementation)
- `__groot` - returns git root (parent of all worktrees)

### Prompt Behavior

The fish prompt (bobthefish theme with custom fork):
- Hides branch name if on main/master
- Hides directory name (since it matches branch name)
- Shows branch name for non-default branches

## Fish Shell Configuration

### Aliases

```bash
ccat        # bat without line numbers (for copying)
cat         # aliased to bat
cp          # cp -v (verbose)
dps         # docker ps with custom format
grb         # git pull origin (default_branch) --rebase
l           # lsd -l --group-dirs first
mv          # mv -v (verbose)
rm          # rm (no -rf by default)
s           # sclone (probably related to clone)
vi          # vim
```

### Abbreviations

```bash
b           # bazel
d           # docker
g           # git
gtv         # go test -v .
gt          # go test ./...
gt.         # go test .
gb          # go build ./...
gb.         # go build .
gd          # go doc -all
gdm         # git diff origin/(default_branch)...
gds         # git diff --stat
k           # kubectl
kctx        # kubectl ctx
rebuild     # darwin-rebuild switch --flake ~/.nixpkgs
tat         # tmux a -t
tan         # tmux new -s
tf          # terraform
untar       # tar -xvf
```

### Key Bindings

```
Ctrl+O (insert)     # fzf directory search
Ctrl+R (insert)     # fzf command history (custom _rzf)
Ctrl+E (insert)     # kubectl fzf autocomplete
Alt+Backspace       # backward-kill-word
Alt+Left            # prevd-or-backward-word (changed from Fish 4.0 token behavior)
Alt+Right           # nextd-or-forward-word
groot (anywhere)    # expands to git root path at cursor
```

### Plugins

- `z` (jethrokuan/z) - directory jumping
- `fzf.fish` (PatrickF1) - fzf integration
- `bobthefish` (custom fork: tommyknows/theme-bobthefish) - prompt theme with worktree support
- `autopair` - auto-close brackets/quotes
- `docker-autocompletions` - docker completions (noted as not working perfectly)

### Functions Location

All fish functions are automatically loaded from `programs/fish/functions/*.fish` and registered by name. The configuration uses `lib.mapAttrs'` to read all `.fish` files and register them.

Work-specific functions are in `work/functions/*.fish` and loaded conditionally.

## Git Configuration

### Commit Signing

- Uses SSH signing (not GPG)
- Signing key configured via Secretive app: `com.maxgoedjen.Secretive.SecretAgent`
- Different email/key for work vs private (conditional on `gitdir:~/Documents/work/`)
- Work email: `ramon.ruttimann@infracost.io`
- Private email: `me@ramonr.ch`

### Key Aliases

```bash
git br              # branch
git c               # commit -S
git ca              # commit -S --amend
git cn              # commit -S --no-verify
git cna             # commit -S --no-verify --amend
git hash            # rev-parse HEAD (no newline)
git msg             # log last commit message
git mrnotes         # format commits for MR notes, copy to clipboard
git plomr           # pull origin (default_branch) -r
git pu              # push -u
git puf             # push -u --force
git put             # push --tags
git pum             # push -u -o merge_request.create (GitLab)
git st              # status
git lg              # pretty log graph
git fix             # calls fish git-fix function
git root            # rev-parse --show-toplevel
git pick-commit     # calls fish git-pick-commit function
```

### Merge Configuration

- Uses `mergiraf` merge driver (AST-aware merging)
- Conflict style: `zdiff3`
- Algorithm: `histogram`
- Color moved: `plain`
- Auto-updates refs on rebase: `updateRefs = true`

### Other Git Settings

- Delta pager enabled with Monokai Extended Origin theme, side-by-side diffs
- git-absorb configured: maxStack=50, oneFixupPerCommit=true
- Prune remote branches automatically
- Rewrite HTTPS GitHub URLs to SSH
- Default branch: `main`
- Pull rebase: true
- Sort branches by committerdate, tags by version

## Vim Configuration

**Important:** Uses `vim`, not `neovim` (TODO in README to migrate)

### Plugin Manager

Uses nix-managed vim plugins (not vim-plug or similar). Plugins defined in `programs/vim/default.nix`.

### Key Plugins

- `coc-nvim` - LSP and completion (with language-specific extensions)
  - coc-go, coc-tsserver, coc-rust-analyzer, coc-sh, coc-yaml, coc-json, etc.
- `vim-fugitive` - Git integration
- `fzf-vim` - Fuzzy finding
- `vim-tmux-navigator` - Seamless tmux/vim navigation
- `vim-tmux-clipboard` - Shared clipboard between vim and tmux
- `tagbar` - Code outline viewer
- `vim-test` - Test runner
- `vimspector` - Debugger
- `nerdcommenter` - Commenting
- `vim-sandwich` - Surround text objects
- `vim-material-monokai` - Color scheme (custom fork: tommyknows)
- `vim-gopher` - Go-specific helpers (custom fork: arp242)

### Settings

- `shiftwidth=4`, `tabstop=4`
- `number=true` (line numbers)
- `mouse=a` (mouse enabled)
- `ignorecase=true`, `smartcase=true`
- `background=dark`
- `undodir=/tmp/vim-undo`

### Configuration Files

All vim config is in `programs/vim/`:
- `default.nix` - plugin and settings management
- `vimrc` - additional vim configuration
- `coc-settings.json` - CoC configuration
- `ftplugin/*.vim` - filetype-specific settings

## Tmux Configuration

### Key Settings

- Base index: 1 (windows and panes start at 1)
- Escape time: 1ms
- Key mode: vi
- Terminal: xterm-256color
- Shell: fish

### Plugins

- `vim-tmux-navigator` - seamless vim/tmux navigation
- `battery` - battery status in status bar (with custom status bar config)
- `yank` - clipboard integration
- `resurrect` - session persistence

### Status Bar

Custom status bar with:
- Session name (left)
- Window list
- Battery percentage and icon
- Time (24-hour)
- Date
- "TRIGGERED" indicator when prefix is pressed

## Packages and Tools

### Language Toolchains

- **Go:** gopls, golangci-lint, delve, gotags, gotestsum, gotools, mockgen
- **Rust:** rustup, rust-vim
- **Node:** nodejs_22, yarn, npm packages (prettier, markdownlint-cli, ts-node, typescript, cspell)
- **Python:** python310

### Cloud/DevOps

- awscli2, aws-vault, amazon-ecr-credential-helper
- google-cloud-sdk, google-cloud-sql-proxy
- kubectl, kubectl-convert, kubernetes-helm, krew, kustomize, k9s
- docker (via Docker Desktop, not Nix)
- kind, ctlptl, rancher, qemu
- terraform, terraform-ls
- tilt
- circleci-cli

### Modern Unix Replacements

- `bat` (cat) - with syntax highlighting
- `lsd` (ls) - modern ls with colors
- `fd` (find) - fast file finder
- `ripgrep` (grep) - fast text search (configured with --smart-case, --hidden, --glob !.git)
- `sd` (sed) - modern sed
- `fzf` - fuzzy finder

### Security/Secrets

- gnupg
- gitleaks
- snyk
- ngrok
- teleport
- wireguard-go, wireguard-tools

### Other CLI Tools

- gh (GitHub CLI), gh-dash (configured)
- glab (GitLab CLI)
- git-absorb, mergiraf
- pre-commit
- jq, jless, yq
- hyperfine (benchmarking)
- tokei (code statistics)
- translate-shell
- protobuf, buf, protoc-gen-go
- ffmpeg, mpv
- qrencode
- universal-ctags
- shellcheck, shfmt, fish-lsp
- b3sum
- crush (unstable, Charm CLI tool)

### GUI Applications

- alacritty (terminal, managed by home-manager)
- slack
- zed-editor
- Safari (system, preferred browser with AdBlock + Vimari extension)
- Mail.app (system)
- Calendar.app (system)

## macOS System Preferences

Configured in `darwin/system.nix`:

### Dock

- Auto-hide: enabled
- Don't rearrange spaces by most-recent use
- Persistent apps: Safari, Mail, Maps, Calendar, Signal, Emby, Alacritty

### Finder

- View style: list view (Nlsv)
- Show all extensions: true
- Quit menu item: enabled
- Disable extension change warning

### Global

- Disable automatic capitalization, dash/period/quote substitution, spell correction
- Hide menu bar
- Expanded save dialogs by default
- Tap to click enabled
- Three-finger drag enabled
- Caps Lock → Escape remapping

### Security

- Screensaver password: immediate
- Touch ID for sudo (pam.services.sudo_local)

## Font Requirements

The configuration expects **SauceCodePro Nerd Font** (now managed via nix: `pkgs.nerd-fonts.sauce-code-pro`).

Fallback: [Liga Sauce Code Pro Nerd Font](https://github.com/Bo-Fone/Liga-Sauce-Code-Pro-Nerd-Font)

## Initial Setup Requirements

When setting up a new machine:

1. Install Nix (Determinate Systems installer recommended, based on `nix.enable = false` in config)
2. Install nix-darwin
3. Symlink nix-channels:
   ```bash
   ln -s $(realpath ./nix-channels) ~/.nix-channels
   ```
4. Run initial rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.nixpkgs#work-laptop
   # or
   darwin-rebuild switch --flake ~/.nixpkgs#private-laptop
   ```
5. Setup "Internet Accounts" (not managed by Nix)
6. Install Docker Desktop manually (not in Nix)
7. Set GITHUB_TOKEN as universal fish variable:
   ```bash
   set -Ux GITHUB_TOKEN "your-token"
   ```

## Important Gotchas and Patterns

### Nix Management

- **Nix is NOT managed by nix-darwin** (`nix.enable = false`) - it's installed via Determinate Systems installer
- Always use flake commands with `--flake` flag
- Config expects to be at `~/.nixpkgs` (or adjust flake commands)
- Unfree packages must be in allowlist (`allowed-unfree-packages` in flake.nix)

### Git Worktree Structure

- **NEVER** `git checkout` in the root directory (where `.git` lives)
- Each branch has its own directory: `repo/branch-name/`
- The `.git` directory is in the repository root (parent of all branch directories)
- Use `c` or `w` commands exclusively for branch switching
- Symlinks are created between worktrees for local config files: `config.local.json`, `.local-dev-deps`, `tools/node_modules`, `tools/.bin`

### Fish Function Patterns

- Functions that need to modify shell state (like `cd`) MUST be fish functions, not scripts
- Autocompletion scripts are separate files in `programs/fish/completions/`
- Functions automatically registered by filename (no manual sourcing needed)
- Use `(command_in_subshell)` syntax for command substitution in fish

### Path Configuration

Go workspace is at `~/Documents/go` (not `~/go`), configured via:
```nix
programs.go.goPath = "Documents/go";
```

Work directory for repositories: `/Users/ramon/Documents/work`

### SSH Configuration

SSH agent uses Secretive app:
```
SSH_AUTH_SOCK = ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
```

### Git Hooks

Git hooks path is set to: `/Users/ramon/.nixpkgs/programs/git/hooks`

### Clipboard Integration

- tmux ↔ vim: working
- tmux ↔ system: working  
- vim ↔ system: **NOT working yet** (TODO in README)

### Ripgrep Configuration

Ripgrep is configured globally with:
- `--smart-case` (case-insensitive unless pattern has uppercase)
- `--hidden` (search hidden files)
- `--glob !.git` (exclude .git directories)

These settings are always active when using `rg`.

## Testing and Validation

### After Configuration Changes

1. Format nix files: `alejandra .`
2. Rebuild: `darwin-rebuild switch --flake ~/.nixpkgs`
3. Check for errors in output
4. For program changes: restart terminal or reload config
5. For system changes: some require logout/restart

### Common Issues

- **"infinite recursion"**: usually circular imports or incorrect overlay
- **"unfree package"**: add package to `allowed-unfree-packages` in flake.nix
- **Programs not found after rebuild**: check PATH in fish, may need terminal restart
- **Git signing fails**: verify Secretive app is running and key is accessible
- **Worktree commands fail**: ensure you're in a git repository with proper structure

## References and Documentation

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [home-manager manual](https://nix-community.github.io/home-manager/)
- [Nix flakes](https://nixos.wiki/wiki/Flakes)
- Custom forks used:
  - bobthefish: tommyknows/theme-bobthefish (worktree support)
  - vim-material-monokai: tommyknows/vim-material-monokai

## Work-Specific Configuration

When `work_toggle = "enabled"`:
- Git email: `ramon.ruttimann@infracost.io`
- Git signing key: work-specific key via Secretive
- Additional fish functions from `work/functions/`:
  - `aws-console.fish`
  - `sync-crds.fish`
  - `validate-chart.fish`
- `WORK_GITHUB_USER` set to "infracost"
- Go private modules: `github.com/infracost`

## TODOs and Known Issues

From README and config comments:

1. **Vim → Neovim migration**: Still using vim, not neovim
2. **Vim ↔ System clipboard**: Not working yet
3. **Docker autocompletions**: Not working perfectly (container ID completion)
4. **GITHUB_TOKEN refresh**: Currently set as universal variable, could be async-refreshed
5. **Kubebuilder package**: Not available (needs etcd, apiserver bundled)
6. **Fish abbr groot**: Waiting for next home-manager release for `--set-cursor` support
7. **Go GOFLAGS**: Waiting for next home-manager release, manually set with `go env -w GOFLAGS="-buildvcs=false"`
