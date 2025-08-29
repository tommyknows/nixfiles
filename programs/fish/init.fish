fish_hybrid_key_bindings

set -g EDITOR vim
set -g LANG C
# prompt customisation
set -g theme_nerd_fonts yes
set -g theme_title_display_process yes
set -g theme_display_vi yes
set -g theme_color_scheme dark
set -g theme_git_worktree_support yes

fzf_configure_bindings --directory=\co
set fzf_preview_file_cmd bat --line-range :50 --color=always --style=rule
set fzf_preview_dir_cmd lsd --almost-all --long --total-size --color=always
set fzf_dir_opts --height=50 --bind='ctrl-v:execute(vim {} &> /dev/tty)'

bind \eo _kubectl_fzf_autocomplete
bind -M insert \eo _kubectl_fzf_autocomplete
bind \er _rzf
bind -M insert \er _rzf

bind -M insert alt-backspace backward-kill-word
# Fish 4.0 changed the behaviour of alt-left and right to travel
# full "tokens" instead of words. 
# > alt-left and alt-right will now move by one argument (which may 
# > contain quoted spaces), not just one word like ctrl-left and 
# > ctrl-right do.
# ctrl-left and right are unusable on Mac because they're used to 
# switch desktops, so we change the behaviour back.
bind -M insert alt-left prevd-or-backward-word
bind -M insert alt-right nextd-or-forward-word

fish_add_path --path --move --prepend /Users/ramon/Documents/go/bin \
    /Users/ramon/.nix-profile/bin \
    /run/current-system/sw/bin \
    /nix/var/nix/profiles/default/bin \
    /usr/local/bin

fish_add_path --path --move --append $HOME/.krew/bin \
    $HOME/.npm-packages/bin

# TODO: remove? I don't even remember why I have it.
function __disable_ctx_on_aws_exit --on-event fish_exit
    if test \
            \( -n "$AWS_VAULT" \) -a \
            \( "$theme_display_k8s_context" = yes \) -a \
            \( "$theme_display_k8s_namespace" = yes \) && string match -r '^aws-.*' (command kubectl ctx -c)
        tkctx
    end
end

set -gx BAT_THEME "Monokai Extended"

# set the cursor to a block even in insert mode. Otherwise it'd be a line.
# see https://fishshell.com/docs/current/interactive.html#vi-mode
set -gx fish_cursor_insert block

# TODO: this is uncommented because it slows down startup.
# I've set this as a universal variable now, which however means
# it won't be updated automatically.
# Ideally, we'd refresh this asynchronously on a specific interval.
#set -gx GITHUB_PRIVATE_TOKEN (security find-generic-password -a "$USER" -s "GitHub Token" -w)

set -gx SSH_AUTH_SOCK "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

abbr -a groot --position anywhere --function __groot --set-cursor=!
