# this "works" when added to a binding (e.g. `bind \cc copy` -> enter command, esc, ctrl+c).
# Three caveats:
# - Ugly?
# - Will eat newlines in the command.
# - Bound to \cc, it requires the user to get into normal mode.
#
# Having a simple command to pipe to doesn't work because we can't read the commandline.
# We could write a wrapper script or something:
# copy echo "hello" | rg
# The issue is that pipes will be executed as separate pipelines unless escaped :/
echo \$ (commandline) > /tmp/output
commandline -a ' | tee /dev/tty 2>&1 >> /tmp/output && cat /tmp/output | pbcopy'
commandline -f execute
