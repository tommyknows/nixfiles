set sha (git-pick-commit)
if string match "$sha" "" 
    exit
end

if ! git diff --quiet
    git stash --keep-index --include-untracked
    set stashed true
end

git commit --fixup "$sha"
env GIT_SEQUENCE_EDITOR=true git rebase --interactive --autosquash "$sha^"

if test -n "$stashed"
    git stash pop
end
