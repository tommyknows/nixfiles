#sudo TELEPORT_HOME=$HOME/.tsh kubectl \
#--context snyk-main-dev16 \
#--namespace infra \
#port-forward service/polaris-charts 80:80 &
#
#while ! sudo lsof -Pn -i4 | rg 'kubectl' | rg '127.0.0.1:80'
#    sleep 1
#    echo "...waiting for port-forward to be up"
#end
## not using helm dependency build as that needs repositories to be added.
#helm dependency update
#
#sudo kill (jobs %1 --pid)
#sudo chown ramon -R ~/.tsh/keys/snyk.teleport.sh/

astro helm dependency-update --context=dev16
