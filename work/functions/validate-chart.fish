# print stdout only on success, as to not clutter the error-output.
if set output (astro helm template  | kubectl apply --dry-run=server --context=docker-desktop -f - 2>/dev/tty)
    printf "%s\n" $output
end
