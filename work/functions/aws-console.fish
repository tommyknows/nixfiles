open (cat ~/.aws/config | rg 'sso_start_url = (.+)$' --replace '$1')
