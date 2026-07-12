#!/usr/bin/env sh
set -e
working_dir="$1"
pane_id="$2"
current_cmd="$3"
trap 'echo $working_dir' ERR INT TERM

pushd $working_dir > /dev/null
# VCS identity (mirrors the shell prompt): jj if a .jj store sits at/above
# $working_dir, else git. Walk up for .jj but stop at a .git boundary, so a git
# worktree under a jj-colocated bare root still renders as git.
jj_root=""
d="$working_dir"
while [ -n "$d" ]; do
  if [ -d "$d/.jj" ]; then jj_root="$d"; break; fi
  if [ -e "$d/.git" ]; then break; fi
  if [ "$d" = "/" ]; then break; fi
  d="$(dirname "$d")"
done

if [ -n "$jj_root" ]; then
  # jj branch: guard every call with `|| true` so set -e + the ERR trap don't
  # swallow a valid jj workspace into the full-path fallback.
  #
  # Locate the repo root without git (jj-native clones have no .git at all): the
  # store `.jj/repo` is a real directory at the repo root and a pointer *file* in
  # secondary workspaces. So if jj_root holds the store it IS the repo root;
  # otherwise jj_root is a workspace and the repo root is its parent.
  if [ -d "$jj_root/.jj/repo" ]; then
    project_dir="$(basename "$jj_root")"
  else
    project_dir="$(basename "$(dirname "$jj_root")")"
  fi
  # Identity like a git branch: the bookmark on @, else the workspace dir name
  # (when distinct from the repo), else the change-id.
  jj_data="$(jj log --ignore-working-copy --no-graph --color never -r @ -T 'bookmarks.join(",") ++ "\t" ++ change_id.shortest(8)' 2> /dev/null || true)"
  tab="$(printf '\t')"
  bookmarks="${jj_data%%${tab}*}"
  if [ "$jj_data" = "${jj_data#*${tab}}" ]; then change_id=""; else change_id="${jj_data##*${tab}}"; fi
  ws_name="$(basename "$jj_root")"
  if [ -n "$bookmarks" ]; then
    branch_name="$bookmarks"
  elif [ "$ws_name" != "$project_dir" ]; then
    branch_name="$ws_name"
  else
    branch_name="$change_id"
  fi
else
  # git branch: a failing rev-parse (non-repo dir) trips set -e → the ERR trap
  # echoes the full $working_dir as the title. That fallback is intentional.
  rev_parse=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ "$(dirname "$(git rev-parse --git-dir)")" = "$rev_parse" ]; then
    project_dir="$(basename "$rev_parse")"
  else
    project_dir="$(basename "$(dirname "$rev_parse")")"
  fi
  branch_name="$(git symbolic-ref HEAD 2> /dev/null | sed "s/^refs\/heads\///g")"
fi

if [ "${#project_dir}" -gt 16 ] && printf '%s' "$project_dir" | grep -q "-"; then
  # foo-bar_baz -> fbb
  project_dir=$(printf '%s' "$project_dir" | sed -E 's/([a-zA-Z0-9])[a-zA-Z0-9]*[_\-]?/\1/g')
fi

if [ -n "$branch_name" ]; then
  name="$project_dir/$branch_name"
else
  name="$project_dir"
fi
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
