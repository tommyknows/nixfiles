# __jj_ws_links <groot> <dir> <default_branch>
#
# Set up the per-workspace bookkeeping shared by `c` (jj path) and `jj-init`:
# the `.claude` dir, the shared local-config symlinks (sourced from the default
# branch's workspace), and the ~/.claude/projects canonical↔link symlink so
# `--resume` sees full history from any workspace.
set -l groot $argv[1]
set -l dir $argv[2]
set -l default_branch $argv[3]

mkdir -p $dir/.claude

for fileOrDir in "config.local.json" ".local-dev-deps" tools/node_modules "tools/.bin"
    if [ -e $groot/$default_branch/$fileOrDir -a ! -f $dir/$fileOrDir ]
        ln -s $groot/$default_branch/$fileOrDir $dir/$fileOrDir
    end
end

set -l _claude_canonical ~/.claude/projects/(string replace -a / - $groot)
set -l _claude_link ~/.claude/projects/(string replace -a / - $dir)
mkdir -p $_claude_canonical
if test ! -e $_claude_link; and test ! -L $_claude_link
    ln -s $_claude_canonical $_claude_link
end
