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

# adjust the path. by default, the nix paths are after the default system paths.
# this makes it annoying with default applications like vim, which are installed
# on the system already too.
set PATH /Users/ramon/Documents/go/bin \
    /Users/ramon/.nix-profile/bin \
    /run/current-system/sw/bin \
    /nix/var/nix/profiles/default/bin \
    /usr/local/bin \
    /usr/bin \
    /bin \
    /usr/sbin \
    /sbin \
    /Library/Apple/usr/bin \
    $HOME/.krew/bin  \
    $HOME/.npm-packages/bin

# TODO: remove? I don't even remember why I have it.
function __disable_ctx_on_aws_exit --on-event fish_exit
    if test \
        \( -n "$AWS_VAULT" \) -a \
        \( "$theme_display_k8s_context" = "yes" \) -a \
        \( "$theme_display_k8s_namespace" = "yes" \) && \
        string match -r '^aws-.*' (command kubectl ctx -c)
        tkctx
    end
end

set -gx BAT_THEME "Monokai Extended"

# TODO: that token's probably expired, but I'm leaving this here as an example on how to read out the keychain.
set -gx GITHUB_PRIVATE_TOKEN (security find-generic-password -a "$USER" -s "GitHub Token" -w)

abbr -a groot --position anywhere --function __groot --set-cursor=!
