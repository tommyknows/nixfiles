if count $argv > /dev/null
    set query "-q $argv" "-1"
end
aws-vault exec (aws-vault list --profiles | fzf $query)
