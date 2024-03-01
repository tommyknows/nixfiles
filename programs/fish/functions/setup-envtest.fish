if string match "$argv[1]" "use"
    command setup-envtest $argv -p env | source
else
    command setup-envtest $argv
end
