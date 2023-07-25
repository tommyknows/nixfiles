argparse --exclusive 'directory,repository' 'd/directory=' 'r/repository=' -- $argv

# check if the repository flag is set. If it is, it means that we want to fetch info from a *remote*, not locally
# checked out, repository.
if set --query _flag_repository
    # list remote tags and sort them accordingly.
    for ref in (git ls-remote -ht git@github.com:snyk/(basename $_flag_repository) | awk '{print $2}')
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

if set --query _flag_directory
    pushd $_flag_directory
end


set local_branches (git branch | awk '{print $2}')
# check if we're in a worktree, and if so, remove the current branch / worktree from the suggestions.
if git rev-parse --show-toplevel >/dev/null 2>&1 
    set -l current_branch (git rev-parse --abbrev-ref HEAD)
    set -e local_branches[(contains -i $current_branch $local_branches)]
end
printf '%s\n' $local_branches

if set --query argv[1]
    switch $argv[1]
        case "v*"
            git for-each-ref --format='%(refname:short)' refs/tags | rg -v (string join "|" $local_branches) |sed '/-/!s/$/_/' | sort -rV | sed 's/_$//'
        case "o*"
            # fetch the branches in the background. When the user then autocompletes to "origin" with <TAB>,
            # the new branches should (hopefully) show up by then already.
            git fetch >/dev/null 2>&1 &
            git for-each-ref --format='%(refname:short)' refs/remotes/origin \
                # exclude some branches / names
                | rg -v 'origin/HEAD' | rg -v '^origin$'
    end
end

if set --query _flag_directory
    popd
end
