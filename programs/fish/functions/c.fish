# `c` — create / switch a worktree-or-workspace in the current repo.
#
# Dispatches on repo type: a repo converted to jj (<root>/.jj/repo exists, created
# explicitly by `jj-init`) uses jj workspaces; a plain git repo falls back to `gc`
# (git worktrees). `c` never converts a repo — run `jj-init` for that. Call `gc`
# directly to force git worktrees even inside a jj repo.

# Dispatch first, forwarding the raw args to the git impl when this isn't a jj repo
# (or we're not in a repo at all — gc handles help/errors).
set -l groot (repo_root)
if test $status -ne 0
    gc $argv
    return
end
if not test -d $groot/.jj/repo
    # git impl (gc) uses git's origin/<branch> form, so translate -o/--origin <branch>
    # into that, keeping `c -o foo` uniform across jj and git repos.
    set -l fwd
    set -l want_origin 0
    for a in $argv
        switch $a
            case -o --origin
                set want_origin 1
            case '*'
                if test $want_origin -eq 1
                    set -a fwd "origin/$a"
                    set want_origin 0
                else
                    set -a fwd $a
                end
        end
    end
    gc $fwd
    return
end

# ----------------------------- jj workspace impl -----------------------------
set -l helptext "c - switch / create jj workspaces (this repo is jj; run `gc` to force git).

c [OPTIONS] [NAME [BASE]]

DESCRIPTION
c creates and switches between jj workspaces — sibling directories next to the bare
.git and the bare .jj store. If NAME is omitted, c switches to the default-branch dir.
If the workspace directory already exists (jj workspace OR git worktree), c switches
to it. Otherwise a new jj workspace is created.

BASE selects the revision the new workspace branches off:
  - if given, it must be a valid jj revset (a bookmark, change-id, tag).
  - otherwise it defaults to the current workspace's @ (stacking-friendly), falling
    back to trunk() (the default branch) when @ can't be resolved.

With -o (or the 'origin/NAME' alias), the matching remote bookmark is fetched and
tracked. A bookmark named after NAME is created at the new @ (for PR pushes); skipped
for the default branch.

OPTIONS
-o or --origin   Check out / track a remote (origin) branch (≈ git 'origin/NAME').
-t or --ticket   Store a ticket reference for later extraction when committing.
-h or --help     Display this help.

EXAMPLES
`c`                 switches to the default-branch directory.
`c my-feature`      creates a jj workspace 'my-feature' off the current @.
`c hotfix trunk()`  creates 'hotfix' branched off the default branch.
`c -o pr-123`       fetches and tracks the remote bookmark pr-123.
`c origin/pr-123`   same, via the compat alias.
"

argparse 't/ticket=' o/origin h/help -- $argv
if set --query _flag_help
    printf '%b' $helptext
    return
end

set -l bare $groot/.git
set -l default_branch (default_branch)

# Resolve the workspace name + directory.
set -l name $argv[1]
test -z "$name"; and set name $default_branch

# -o/--origin, or an 'origin/<x>' name (compat alias), means: fetch + track the
# remote bookmark <x>.
set -l track_upstream false
if set -q _flag_origin
    set track_upstream true
end
if string match -q 'origin/*' -- "$name"
    set name (string replace 'origin/' '' -- "$name")
    set track_upstream true
end

set -l dir_leaf (string replace -a "/" "_" -- "$name")
set -l dir $groot/$dir_leaf

# Already exists (jj workspace or git worktree)? Just switch.
if test -d $dir
    cd $dir
    return
end

# Classify NAME so we check out an existing branch instead of branching off @ for it
# (mirrors git `c`: existing branch → check out; new name → create off @/base).
set -l locals  (jj -R $groot bookmark list -T 'name ++ "\n"' 2>/dev/null)
set -l remotes (jj -R $groot bookmark list -a -T 'if(remote == "origin", name ++ "\n")' 2>/dev/null)

set -l base $argv[2]
set -l mode  # explicit | track | checkout-local | new
if test -n "$base"
    set mode explicit                                  # c NAME BASE → new branch off BASE
else if test "$track_upstream" = true
    set mode track; set base "$name@origin"            # c origin/NAME → track remote
else if contains -- $name $locals
    set mode checkout-local; set base $name             # existing bookmark → check it out
else if contains -- $name $remotes
    set mode track; set track_upstream true; set base "$name@origin"  # remote-only → track
else
    set mode new                                        # brand-new branch off current @
    set base (jj log --no-graph --no-pager -r @ -T change_id 2>/dev/null | string trim)
    test -z "$base"; and set base 'trunk()'
end

# Fetch when we're tracking a remote bookmark (let jj voice the result, for a
# consistent jj-style log rather than a custom echo).
if test "$mode" = track
    jj -R $groot git fetch
end

if not jj -R $groot workspace add --name $dir_leaf -r $base $dir
    echo "c: failed to create workspace" >&2
    return 1
end

# Bookmark: track remote, create one for genuinely new branches, leave existing alone.
if test "$name" != "$default_branch"
    switch $mode
        case track
            jj -R $groot bookmark track $name --remote=origin 2>/dev/null
        case new explicit
            jj -R $dir bookmark create $name -r @ 2>/dev/null
    end
end

__jj_ws_links $groot $dir $default_branch

# Ticket note: store explicitly via -t, else inherit from the current branch.
# Best-effort (git config still reads/writes via the shared bare store).
set -l ticket_ref "$_flag_ticket"
if test -z "$ticket_ref"
    set ticket_ref (git config branch.(git rev-parse --abbrev-ref HEAD 2>/dev/null).note 2>/dev/null)
end
if test -n "$ticket_ref"
    git config branch.$name.note $ticket_ref 2>/dev/null
end

cd $dir
