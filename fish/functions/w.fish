set -l workdir "/Users/ramon/Documents/work"

if ! set -q argv[1]
    cd $workdir
end

set commit $argv[3]

if string match -q '*github.com/snyk/*' $argv[1]
    set repo (string replace -r '.*github.com/snyk' '' $argv[1] | string replace -r '/$' '')
    if echo $repo | rg -q '/pull/[0-9].*'
        set -l pull_info (string match -r '/?(.*)/pull/(.*)' -g $repo)

        set repo $pull_info[1]
        set branch (curl -L --silent \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_PRIVATE_TOKEN"\
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/snyk/$repo/pulls/$pull_info[2] | jq .head.ref -r)
    end
else
    set repo $argv[1]
    set branch $argv[2]
    set commit $argv[3]
end

set dir $workdir/$repo
if [ ! -d $dir ]
    if ! s $repo
        return
    end
else
    cd $dir
end

if [ -z $branch ]
    set branch (default_branch)
end

c $branch $commit
