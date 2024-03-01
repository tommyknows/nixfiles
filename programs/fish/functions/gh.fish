# gh opens the current repository in a web browser
set matches (string match -r 'git@github.com:(.*)\.git' (git remote get-url origin))
open "https://github.com/$matches[2]"
