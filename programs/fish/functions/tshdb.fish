switch $argv[1]
    case "connect"
        set cmd "tsh db connect"
    case "proxy"
        set cmd "tsh proxy db --tunnel"
    case '*'
        echo "specify tsh command to use: [connect | proxy]"
        return
end

if set -q argv[2]
    set filter "service=$argv[2]"
end

set output (tsh db ls $filter -f json \
| jq -r '["Instance Name","DB Name", "Allowed Users"], (.[] | [.metadata.name, (.metadata.labels."db-name" // "-"), (.users.allowed | join(","))]) | @tsv' \
| column -t -s \t \
| fzf --header-lines=1 \
| string split --no-empty ' ') || return

set instance $output[1]
if test $output[2] != "-"
    set dbname $output[2]
else 
    read -p "echo Enter DB Name:\ " dbname || return
    if test -z "$dbname" 
        echo "no DB name given, aborting"
        return
    end
end

set user (echo $output[3] | string split ',')
if test (count $user) -gt 1
    set user (string join0 $user | fzf --read0 --header="Select user") || return
end

echo "Connecting to DB $instance with user $user..."
commandline --replace "$cmd --db-name=$dbname --db-user=$user $instance" 
commandline --function execute
