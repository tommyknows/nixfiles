set sso_session (cat ~/.aws/config | rg '\[sso-session (.+)\]$' --replace '$1')
set sso_url (cat ~/.aws/config | rg 'sso_start_url = (.+)$' --replace '$1')

set expiry_date (cat ~/.aws/sso/cache/*.json | jq '. | select(.startUrl=="'$sso_url'") | .expiresAt' -r)
set expiry_timestamp (date -d "$expiry_date" +%s)
set refresh_token_expiry (math $expiry_timestamp + 8 \* 3600)
set now_timestamp (date -d now +%s)
if test $refresh_token_expiry -lt $now_timestamp
    aws sso login --sso-session $sso_session
end
