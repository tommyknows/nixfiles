if [ (kubectl config current-context) != "docker-desktop" ]
    kubectl ctx docker-desktop
end
command tilt $argv
