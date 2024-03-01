git fetch -p
for branch in (git branch -vv | awk '{print $1,$4}' | rg 'gone]' | awk '{print $1}')
    git branch -D $branch
end
