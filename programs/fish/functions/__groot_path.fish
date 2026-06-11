set -l root (git rev-parse --show-toplevel 2>/dev/null)
if test -z "$root"
    return 1
end
set -l rel (realpath --relative-to=(pwd) -- $root)
set -l rest (string sub -s 3 -- $argv[1])
if test -z "$rest"
    echo $rel/%
else
    echo $rel/$rest%
end
