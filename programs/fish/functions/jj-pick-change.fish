# jj-pick-change [REVSET] — interactively pick a jj change and print its change-id.
# The jj analogue of git-pick-commit.
#
# The whole graph for REVSET (default all()) is shown. fzf "raw mode" dims
# non-matching changes instead of hiding them, so the topology stays intact; up/down
# are rebound to up-match/down-match so the cursor skips dimmed (non-matching)
# changes as you type. change:best keeps the cursor on the best match.
#
# Two ways to narrow:
#   - live query = fzf fuzzy over the oneline text (id, desc, bookmark, date);
#     prefix a term with ' for an exact match (precise change-ids).
#   - ctrl-r = re-scope the graph to the current query interpreted as a jj REVSET
#     (mine(), trunk()..@, …), then clear the query to fuzzy-narrow within it.
# REVSET as an argument seeds the initial scope for non-interactive callers.
#
# Records (change + trailing graph-only lines bundled as one --read0 item) are built
# by __jj_pick_records, which fzf also calls on ctrl-r. jj runs in the cwd (no -R):
# the picker is always launched from a workspace, so @ and @-relative revsets
# (trunk()..@) resolve; -R <root> would hit the root's forgotten default workspace.
set -l groot (repo_root 2>/dev/null); or return 1
test -d $groot/.jj/repo; or return 1

set -l scope $argv[1]
test -z "$scope"; and set scope 'all()'

set -l selected (
    __jj_pick_records "$scope" \
        | fzf --read0 --ansi --reverse --no-sort --raw \
            --with-shell 'fish -c' \
            --bind 'up:up-match,down:down-match' \
            --bind 'change:best' \
            --bind 'ctrl-r:reload(__jj_pick_records {q})+clear-query' \
            --prompt 'change> ' \
            --header "fuzzy: id·desc·bookmark  ·  'exact  ·  ctrl-r: query as revset  ·  ↑↓ move"
)

# The command substitution splits the selected item on newlines; its first line is
# the change's oneline (graph glyph + change-id). Strip leading graph symbols, take
# the change-id token; the ^[a-z]+$ guard rejects anything unexpected.
set -l id (string replace -rf '^[^[:alnum:]]*([a-z]+).*' '$1' -- (string trim -- "$selected[1]"))
string match -qr '^[a-z]+$' -- "$id"; and echo $id
