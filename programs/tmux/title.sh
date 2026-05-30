#!/usr/bin/env sh
set -e
working_dir="$1"
pane_id="$2"
current_cmd="$3"
trap 'echo $working_dir' ERR INT TERM

pushd $working_dir > /dev/null
rev_parse=$(git rev-parse --show-toplevel 2> /dev/null)

if [ "$(dirname "$(git rev-parse --git-dir)")" = "$rev_parse" ]; then
  project_dir="$(basename "$rev_parse")"
else
  project_dir="$(basename "$(dirname "$rev_parse")")"
fi

if [ "${#project_dir}" -gt 16 ] && printf '%s' "$project_dir" | grep -q "-"; then
  # foo-bar_baz -> fbb
  project_dir=$(printf '%s' "$project_dir" | sed -E 's/([a-zA-Z0-9])[a-zA-Z0-9]*[_\-]?/\1/g')
fi
branch_name="$(git symbolic-ref HEAD 2> /dev/null | sed "s/^refs\/heads\///g")"

name="$project_dir/$branch_name"
popd > /dev/null

# Claude exception: when this pane is running a `cl`-launched claude
# session, surface the session's title (custom or AI-generated) instead
# of the trailing process name.
#
# Two pane-local markers identify a claude pane:
#   @claude-session  cwd at launch — set by `cl` before claude starts
#   @claude-id       session UUID  — set by claude's SessionStart hook
# @claude-session alone means claude is still starting up (no JSONL yet);
# we render "[c]" without a title until the hook fires.
if [ -n "$pane_id" ]; then
  marker=$(tmux show-options -p -t "$pane_id" -v @claude-session 2>/dev/null || true)
  if [ -n "$marker" ]; then
    id=$(tmux show-options -p -t "$pane_id" -v @claude-id 2>/dev/null || true)
    title=""
    if [ -n "$id" ]; then
      # Claude stores session JSONLs under ~/.claude/projects/<enc>/<uuid>.jsonl
      # where <enc> is the cwd with '/' replaced by '-'.
      enc=$(echo "$marker" | sed 's|/|-|g')
      jsonl="$HOME/.claude/projects/$enc/$id.jsonl"
      if [ -f "$jsonl" ]; then
        # JSONL is append-only; rename events accumulate, so the last
        # occurrence is authoritative. Prefer customTitle (user `/rename`)
        # over aiTitle (auto-generated). grep+sed rather than jq to avoid
        # depending on jq from tmux's format-string subshell.
        title=$(grep -o '"customTitle":"[^"]*"' "$jsonl" | tail -1 | sed 's/^"customTitle":"//;s/"$//')
        [ -z "$title" ] && title=$(grep -o '"aiTitle":"[^"]*"' "$jsonl" | tail -1 | sed 's/^"aiTitle":"//;s/"$//')
      fi
      if [ -n "$title" ] && [ "${#title}" -gt 25 ]; then
        title=$(printf '%s' "$title" | cut -c1-22)...
      fi
    fi
    # "[c]" marks any claude pane; the title is appended when known.
    if [ -n "$title" ]; then
      echo "$name [c] $title"
    else
      echo "$name [c]"
    fi
    exit 0
  fi
fi

if [ -n "$current_cmd" ]; then
  echo "$name $current_cmd"
else
  echo "$name"
fi
