if test $theme_display_k8s_context = "no"
  tkctx
  if [ $argv[1] = "ctx" ]
      return;
  end
  echo "Do you still want to execute the command \"kubectl $argv\"? (Y/n)"
  read -c 'Y' confirmation
  if test -z $confirmation -o $confirmation != "Y"
    echo "aborting..."
    return;
  end
end
command kubectl $argv
