if test "$theme_display_k8s_context" = no
    tkctx orbstack
else if [ (kubectl config current-context) != orbstack ]
    kubectl ctx orbstack
end
command tilt $argv
