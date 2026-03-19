set CONTAINER_NAME petls
switch $argv[1]
    case start
        if docker inspect $CONTAINER_NAME &>/dev/null
            docker start $CONTAINER_NAME
        else
            docker run -d -p 4566:4566 --name $CONTAINER_NAME --restart always localstack/localstack:4.14.0
        end
        set -Ux REPLAY_LOCALSTACK_ENDPOINT "http://localhost:4566"
    case stop
        set -Ue REPLAY_LOCALSTACK_ENDPOINT
        docker stop $CONTAINER_NAME
    case reset
        petdb stop
        docker rm $CONTAINER_NAME
        petdb start
    case status
        set STATUS (docker container inspect --format='{{.State.Status}}' $CONTAINER_NAME 2>/dev/null | string trim)
        if test -z "$STATUS"
            echo removed
        else
            echo "$STATUS"
        end
    case '*'
        echo "Unknown command \"$argv[1]\". Supported commands: 'start', 'stop', 'reset'"
        return 1
end
