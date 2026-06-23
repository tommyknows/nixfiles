# shellcheck shell=bash
#
# Custom `@`-mention file search for Claude Code. The built-in resolves its
# search root via `git rev-parse`, which fails in jj non-colocated workspaces
# (a `.jj` but no `.git`) and falls back to $HOME — so `@`+query returns
# ~/.claude/* instead of project files. We search the enclosing workspace
# directly, no git needed.
#
# Wired in via programs/claude/default.nix (writeShellApplication + readFile),
# which prepends the shebang + `set -euo pipefail` and puts rg/jq/fzf/coreutils
# on PATH — so this file has neither, and is bash per the directive above.
#
# Syntax:
#   @<query>             search the CURRENT workspace (fuzzy)
#   @:                   list sibling worktree names
#   @:<treefuzz>         list sibling worktrees whose name matches <treefuzz>
#   @:<treefuzz>/<path>  search matching sibling worktree(s) for <path>
# A leading ':' marks cross-tree. ('@@' can't work — Claude closes the picker on
# a second '@'; ':' is kept in the query, so the script sees ':<...>'.)
# Cross-tree results are sibling-relative (../<tree>/...) and only resolve in a
# global `cl` session, where siblings are passed via --add-dir.

query=$(jq -r '.query // ""')
limit=15

# Nearest enclosing workspace (in-tree search base): first ancestor with a
# .jj or .git pointer/store. In our layout that's the workspace dir.
base=$PWD
d=$PWD
while [ "$d" != "/" ]; do
  if [ -e "$d/.jj" ] || [ -e "$d/.git" ]; then base=$d; break; fi
  d=$(dirname "$d")
done

# Repo root (dir holding the bare store): ancestor whose .jj/repo OR .git is
# a *directory* — workspace/worktree pointers are files, so we walk past them
# and stop at the real store. Mirrors the `repo_root` fish helper.
root=
d=$PWD
while [ "$d" != "/" ]; do
  if [ -d "$d/.jj/repo" ] || [ -d "$d/.git" ]; then root=$d; break; fi
  d=$(dirname "$d")
done

# Ignore the global ripgreprc (--hidden etc.) for predictable suggestions.
export RIPGREP_CONFIG_PATH=
shopt -s nullglob

# emit_files DIR PREFIX FILTER — DIR's files (relative), fuzzy-ranked by
# FILTER (via fzf, like the built-in @ search), each line prefixed with PREFIX.
emit_files() {
  local dir=$1 prefix=$2 filter=$3 files
  files=$( (cd "$dir" 2>/dev/null && rg --files --glob '!.git' --glob '!.jj' 2>/dev/null) || true)
  [ -n "$filter" ] && files=$(printf '%s\n' "$files" | fzf --filter="$filter" 2>/dev/null || true)
  [ -z "$files" ] && return 0
  if [ -n "$prefix" ]; then
    printf '%s\n' "$files" | while IFS= read -r f; do [ -n "$f" ] && printf '%s%s\n' "$prefix" "$f"; done
  else
    printf '%s\n' "$files"
  fi
}

main() {
  case $query in
    :*)
      # Cross-tree: "@:<treefuzz>[/<pathfuzz>]".
      local rest tree sub dir name
      rest=${query#:}
      [ -z "$root" ] && return 0
      case $rest in
        */*) tree=${rest%%/*}; sub=${rest#*/} ;;
        *)   tree=$rest;         sub= ;;
      esac
      for dir in "$root"/*/; do
        dir=${dir%/}
        name=${dir##*/}
        [ "$dir" = "$base" ] && continue
        { [ -e "$dir/.jj" ] || [ -e "$dir/.git" ]; } || continue
        if [ -n "$tree" ]; then
          case ${name,,} in *"${tree,,}"*) ;; *) continue ;; esac
        fi
        case $rest in
          */*) emit_files "$dir" "../$name/" "$sub" ;;
          *)   printf '../%s/\n' "$name" ;;
        esac
      done
      ;;
    *)
      emit_files "$base" "" "$query"
      ;;
  esac
  return 0
}

main | head -n "$limit" || true
