# bb (byebye) executes the given command in the background, never to be seen or heard again.
fish -c "$argv >/dev/null 2>&1 &"
