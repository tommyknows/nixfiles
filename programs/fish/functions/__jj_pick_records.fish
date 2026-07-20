# __jj_pick_records [REVSET] — emit the changes in REVSET (default all()) as NUL-
# delimited multi-line records for the jj-pick-change fzf picker (--read0). Each
# record is a change's oneline plus the graph-only lines that trail it (branch
# connectors │ ├─╯, `~ (elided revisions)`), so those stay visible but non-selectable.
#
# Used both for the initial list and by fzf's ctrl-r reload (which passes the current
# query as a revset scope), so it must be self-contained. An empty or unparseable
# REVSET falls back to all() — a half-typed revset must never blank the picker. jj
# runs in the cwd (no -R); see jj-pick-change for why.
set -l scope $argv[1]
test -z "$scope"; and set scope 'all()'
jj log -r "$scope" --limit 0 --no-graph -T '""' &>/dev/null; or set scope 'all()'

# Timestamped line → new record; graph-only line → append to the current record.
set -l records
for l in (jj log --no-pager --color=always -r "$scope" -T builtin_log_oneline)
    if string match -qr '\d{4}-\d{2}-\d{2}' -- $l
        set -a records $l
    else if set -q records[1]
        set records[-1] "$records[-1]"\n"$l"
    else
        set -a records $l   # leading graph-only line before any change (unusual)
    end
end
string join0 $records
