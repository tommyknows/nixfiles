tsh kube login \
    --set-context-name=fedramp-alpha-1 \
    --proxy=teleport.c-a.us-east-2.polaris-fedramp-alpha-1.aws.snykgov-internal.net:443 \
    --cluster=teleport.fedramp-alpha.snykgov.io \
    teleport.c-a.us-east-2.polaris-fedramp-alpha-1.aws.snykgov-internal.net

alias kubectl "tsh kubectl"
