#!/usr/bin/env sh
set -e
working_dir="$1"
trap 'echo $working_dir' ERR INT TERM

pushd $working_dir > /dev/null
rev_parse=$(git rev-parse --show-toplevel 2> /dev/null)

if [ "$(dirname "$(git rev-parse --git-dir)")" = "$rev_parse" ]; then
  project_dir="$(basename "$rev_parse")"
else
  project_dir="$(basename "$(dirname "$rev_parse")")"
fi

if [ "$(echo -n "$project_dir" | wc -c)" -gt 16 ] && echo -n "$project_dir" | grep -q "-"; then
  # foo-bar_baz -> fbb
  project_dir=$(echo -n "$project_dir" | sed -E 's/([a-zA-Z0-9])[a-zA-Z0-9]*[_\-]?/\1/g')
fi
branch_name="$(git symbolic-ref HEAD 2> /dev/null | sed "s/^refs\/heads\///g")"

name="$project_dir/$branch_name"
echo "$name"
popd > /dev/null
