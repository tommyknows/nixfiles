if test -n "$argv[1]"
    set title "$argv[1]"
else
    set title Notification
end
if test -n "$argv[2]"
    set description "$argv[2]"
else
    set description (date)
end

set js "var app = Application.currentApplication()
  app.includeStandardAdditions = true
  app.displayNotification(
  \"$description\",
  {withTitle: \"$title\"},
)"

osascript -l JavaScript -e "$js"
