set CONTAINER_NAME petdb
switch $argv[1]
    case start
        if docker inspect $CONTAINER_NAME &>/dev/null
            docker start $CONTAINER_NAME
        else
            docker run -d -p 5432:5432 --env POSTGRES_HOST_AUTH_METHOD=trust --name $CONTAINER_NAME --restart always postgres:18
        end
        set -Ux DB_URL "postgres://postgres@localhost:5432/dashboard_test"
        set -Ux TEST_DB_URL "postgres://postgres@localhost:5432/dashboard_test"
    case stop
        set -Ue DB_URL
        set -Ue TEST_DB_URL
        docker stop $CONTAINER_NAME
    case reset
        petdb stop
        docker rm postgres
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
