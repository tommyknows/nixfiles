complete --command bd --exclusive \
    --keep-order \
    --arguments '(
set --local opts
_c_complete (commandline -ct)
)'
