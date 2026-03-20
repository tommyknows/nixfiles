# completions for "cl" - claude launcher with worktree/repo awareness.

complete --command cl --short-option a --long-option attach --description 'Resume session from .claude/session'

# 1st positional arg: branches in current repo + work dirs + nixfiles
complete --command cl --exclusive \
    --keep-order \
    --condition 'test (count (string match -rv -- "^-" (commandline -opc))) -eq 1' \
    --arguments '(
_c_complete (commandline -ct)
echo nixfiles
command ls ~/Documents/work/
)'

# 2nd positional arg: branch names in the named repo (only when 1st positional arg is a known repo)
complete --command cl --exclusive \
    --keep-order \
    --condition 'test (count (string match -rv -- "^-" (commandline -opc))) -eq 2; and begin
        set --local _repo (string match -rv -- "^-" (commandline -opc))[2]
        test "$_repo" = nixfiles; or test -d ~/Documents/work/$_repo
    end' \
    --arguments '(
set --local _repo (string match -rv -- "^-" (commandline -opc))[2]
if test "$_repo" = nixfiles
    _c_complete --directory ~/Documents/nixfiles (commandline -ct)
else
    _c_complete --directory ~/Documents/work/$_repo (commandline -ct)
end
)'
