# default_branch — print the repo's default branch (main / master).
#
# jj repos (incl. git-less native clones) have no usable git origin/HEAD, so derive it
# from jj's `trunk()` revset alias (e.g. "main@origin" → "main"). Plain-git repos fall
# back to git's origin/HEAD.
set -l root (repo_root 2>/dev/null)
if test -n "$root"; and test -d $root/.jj/repo
    set -l trunk (jj -R $root config get 'revset-aliases."trunk()"' 2>/dev/null)
    if test -n "$trunk"
        string replace -r '@.*' '' -- $trunk
        return
    end
    # fallback: a non-remote bookmark sitting on trunk()
    jj -R $root log --no-graph --no-pager -r 'trunk()' -T 'bookmarks ++ "\n"' 2>/dev/null \
        | string split ' ' | string match -v '*@*' | string match -rv '^$' | head -1
    return
end
git rev-parse --abbrev-ref origin/HEAD | cut -c8-
