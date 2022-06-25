# use --reverse to keep top-down order. Else, the branching-characters don't make sense anymore.
# --select-1 so that if the initial query with the argument already matches only a single commit,
# simply expand that.
set diffs (git log --graph --abbrev-commit --decorate \
    --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' \
    (default_branch)..) 
    
    
if [ -z "$diffs" ]
    set diffs (git log --graph --abbrev-commit --decorate \
    --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)')
end

string join \n $diffs | fzf --reverse --no-sort --query "$argv[1]" --select-1 | rg '.*\*\s+([a-f0-9]*) .*' -r '$1'

