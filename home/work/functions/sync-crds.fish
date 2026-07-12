kubectl get crds -o json --context=pre-prod-mt-gcp-1 |\
    jq 'del(
        .items.[].metadata.uid,
        .items.[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
        .items.[].metadata.selfLink,
        .items.[].metadata.creationTimestamp,
        .items.[].metadata.resourceVersion
        )' |\
    kubectl apply --force-conflicts --server-side -f - > /dev/null
