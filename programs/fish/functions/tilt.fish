if test "$theme_display_k8s_context" = no
    tkctx docker-desktop
else if [ (kubectl config current-context) != "docker-desktop" ]
    kubectl ctx docker-desktop
end
command tilt $argv
