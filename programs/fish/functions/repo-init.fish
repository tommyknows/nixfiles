set -l _git_common (git rev-parse --git-common-dir 2>/dev/null)
if test $status -ne 0
    echo "repo-init: not inside a git repository" >&2
    return 1
end

set -l _groot (path dirname (realpath $_git_common))

# Derive the Claude projects directory key:
# strip leading '/', replace remaining '/' with '-'
set -l _projects_key (string replace -r '^/' '' $_groot | string replace -a '/' '-')
set -l _projects_dir ~/.claude/projects/-$_projects_key

mkdir -p $_projects_dir

if not test -f $_projects_dir/settings.json
    printf '{\n  "permissions": {\n    "deny": [\n      "Edit(%s/master/**)",\n      "Write(%s/master/**)"\n    ]\n  }\n}\n' $_groot $_groot > $_projects_dir/settings.json
end
