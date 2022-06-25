# read command from commandline, trimming away any potential whitespaces and
# splitting all its args into the cmd variable.
set cmd (string split ' ' (string trim (commandline)))
# exit early if the user hasn't specified three args yet or is not calling kubectl.
if test (count $cmd) -lt 2 || test $cmd[1] != "kubectl"
  return
end
set resource $cmd[3]
set options $cmd[4..]
if test $cmd[2] = "logs"
  set resource "pods"
  set options $cmd[3..]
end
# get the name of the resource, passing in all options that the user has
# specified so far. Trim away the header, pass that through FZF and return
# only the name of the resource.
set name (kubectl get $resource $options | tail -n +2 | fzf | awk '{print $1}')
# the user might have aborted the fzf subshell, resulting in an empty name
if test (string length "$name") -eq 0
  return
end
# reset the command line, print the already existing command + the new name.
# We do not want to just append the new name with `commandline -a` so that we can
# handle whitespace a bit better. Also add a space at the end of the command so
# that the user can simply continue typing
commandline (echo "$cmd $name ")
