if test "$theme_display_k8s_context" = "no"
  set -U theme_display_k8s_context "yes"
  set -U theme_display_k8s_namespace "yes"
  command kubectl ctx $argv[1]
  if set aws_profile (string match -r -g '^aws-(.*)' (kubectl ctx -c))
      if test -n "$AWS_VAULT"
          echo "AWS profile is already set. You might need to switch profiles with `actx`"
      else 
        actx "$aws_profile"
      end
  end
else
  set -U theme_display_k8s_context "no"
  set -U theme_display_k8s_namespace "no"
  command kubectl ctx "~~empty~~" > /dev/null
end
true
