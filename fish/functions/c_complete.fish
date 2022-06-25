if [ ! -z "$argv[1]" ]
    # ensure that the directory exists, if not, we can't give any info.
    if [ ! -d $argv[1] ]
        # list remote tags and sort them accordingly.
        for ref in (git ls-remote -ht git@github.com:snyk/(basename $argv[1]) | awk '{print $2}')
            if string match -q 'refs/heads/*' "$ref"
                set -a heads 'origin/'(echo $ref | string replace 'refs/heads/' '')
            else
                set -a tags (echo $ref | string replace 'refs/tags/' '')
            end
        end
        printf '%s\n' $heads
        printf '%s\n' $tags | sed '/-/!s/$/_/' | sort -V | sed 's/_$//'
        return
    end

    pushd $argv[1]
end

set local_branches (git branch | awk '{print $2}')
if git rev-parse --show-toplevel >/dev/null 2>&1 
    set -l current_branch (git rev-parse --abbrev-ref HEAD)
    set -e local_branches[(contains -i $current_branch $local_branches)]
end
printf '%s\n' $local_branches

set -l args (commandline -op)
if [ ! -z "$args[2]" ]
    switch $args[2]
        case "v*"
            git for-each-ref --format='%(refname:short)' refs/tags | rg -v (string join "|" $local_branches) |sed '/-/!s/$/_/' | sort -rV | sed 's/_$//'
            return
        case "o*"
            git for-each-ref --format='%(refname:short)' refs/remotes/origin \
                # exclude some branches / names
                | rg -v 'origin/HEAD' 
            return
    end
end

if [ ! -z "$argv[1]" ] && [ -d $argv[1] ]
    popd
end
