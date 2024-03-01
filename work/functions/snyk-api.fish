if test (count $argv) -lt 5
    set -p argv "api.snyk.io" "Snyk API Token"
end
set API $argv[1]
set TOKEN (security find-generic-password -a "ramon.ruttimann@snyk.io" -s $argv[2] -w)
set ORG_ID $argv[3]
set REQ_PATH $argv[4]
set API_VERSION $argv[5]
set DATA $argv[6]

set JQ_QUERY "."
if test (count $argv) -gt 6
    set JQ_QUERY $argv[7]
end

curl "https://$API/rest/orgs/$ORG_ID/$REQ_PATH?version=$API_VERSION" \
    -X POST -H 'Content-Type: application/vnd.api+json' \
    -H "Authorization: token $TOKEN" \
    -d $DATA 
