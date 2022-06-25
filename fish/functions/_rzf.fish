# read command from commandline, trimming away any potential whitespace
set cmd (string trim (commandline))
set selection (rg --color=always --line-number --smart-case -- "$argv" |
fzf --ansi --multi --delimiter : \
  --with-nth=1,3 \
  --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
  --preview-window +{2}-/2 |
        string split : -f 1 -f 2)

if test -n "$selection[1]"
  commandline (echo "$cmd $selection[1] +$selection[2]")
  commandline -f execute
end
