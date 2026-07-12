# Deploy the NixOS homeserver from the Mac.
#
# Evaluation happens locally; building + switching happen ON the server, so no
# Linux builder is needed for a deploy and there's no commit/push/pull loop.
# Usage: rebuild-server [switch|test|boot|dry-activate]   (default: switch)
#
# NB the flake gotcha: new files must be jj-tracked (or `git add`ed) to be
# visible to the build.
#
# sudo on the server is gated by a TOTP one-time code, which must be entered
# when activation actually runs — so NOT --ask-sudo-password (it prompts once up
# front and the code expires during build/copy). Force a tty (NIX_SSHOPTS -t) so
# the remote sudo can prompt for the code at the moment it switches.
function rebuild-server --description 'nixos-rebuild the homeserver over SSH'
    set -l action switch
    if set -q argv[1]
        set action $argv[1]
    end

    set -lx NIX_SSHOPTS -t
    nixos-rebuild $action \
        --flake "path:$HOME/Documents/nixfiles/main#server" \
        --target-host ramon@server \
        --build-host ramon@server \
        --sudo --no-reexec
end
