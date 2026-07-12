if test "$theme_display_k8s_context" = no
    set -U theme_display_k8s_context yes
    set -U theme_display_k8s_namespace yes
    kctx $argv[1]
else
    set -U theme_display_k8s_context no
    set -U theme_display_k8s_namespace no
    kctx "~~empty~~"
end
true
