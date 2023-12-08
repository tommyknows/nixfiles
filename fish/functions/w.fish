set -l helptext "w - switch to work git repositories and their branches and check out PRs

w [[PROJECT NAME] [BRANCH NAME] [COMMIT SHA / BRANCH] | [PR URL]]

DESCRIPTION
w switches to the work dir (/Users/ramon/Documents/work) and checks out the given project.
If the project should not already exist, it will be cloned automatically. The second and 
third positional argument can be the same as the arguments to the `c` command.

Additionally, if instead of a project name, a Github PR URL is provided, the given repository
will be cloned (if necessary) and the PR's branch opened. The Github PR URL does not need to
be 'clean', e.g. it can also include a trailing `/files` for example.

EXAMPLES
`w snyk-docker-plugin` switches to \"/Users/ramon/Documents/work/snyk-docker-plugin/main\", cloning it if necessary.
`w snyk-docker-plugin my-feature` works the same as the above example, but will check out the branch my-feature.
`w https://github.com/snyk/cli/pull/4959` checks out the branch of PR #4959 in the CLI repo.
"

argparse 'h/help' -- $argv

if set --query _flag_help
    printf '%b' $helptext
    return
end

set -l workdir "/Users/ramon/Documents/work"

if ! set -q argv[1]
    cd $workdir
end

set commit $argv[3]

set -l owner "snyk"

if string match -q '*github.com/*' $argv[1]
    # nice regex to extract the owner, repo, and the PR number.
    set pull_info (string match -r '.*github.com/(.[^/]*)/(.[^/]*)(?:/pull/([0-9]*)(?:/.*)?)?' -g $argv[1])
    set owner $pull_info[1]
    set repo $pull_info[2]
    if test (count $pull_info) -gt 2 
        set -l pr $pull_info[3]
        set branch origin/(curl -L --silent \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_PRIVATE_TOKEN"\
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/$owner/$repo/pulls/$pr | jq .head.ref -r)
    end
else
    set repo $argv[1]
    set branch $argv[2]
    set commit $argv[3]
end

set dir $workdir/$repo
if [ ! -d $dir ]
    if ! clone $owner/$repo $dir
        return
    end
else
    cd $dir
end

if [ -z $branch ]
    set branch (default_branch)
end

c $branch $commit
