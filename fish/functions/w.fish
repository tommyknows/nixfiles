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
