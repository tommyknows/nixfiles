# bb (byebye) executes the given command in the background, never to be seen or heard again.
# Use -l or --log to send output to /tmp/bb.log instead of /dev/null
argparse l/log -- $argv

set -l output /dev/null
if set --query _flag_log
    set output /tmp/bb.log
end

fish -c "$argv >>$output 2>&1 &" >>$output 2>&1 &
