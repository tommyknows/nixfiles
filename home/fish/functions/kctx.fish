set ctx $argv[1]
set old_ctx (command kubectl ctx -c)

if test "$theme_display_k8s_context" = no && test "$old_ctx" = "~~empty~~"
    tkctx "$ctx"
    return
end

if test -z "$ctx"
    command kubectl ctx
else
    command kubectl ctx $ctx >/dev/null
end
if test "$old_ctx" = orbstack
    fish -c "orbctl stop k8s >/dev/null" &
    disown
else
    switch (command kubectl ctx -c)
        case orbstack
            echo "Starting local k8s cluster..."
            fish -c "orbctl start k8s >/dev/null 2>&1 && sleep 2 && notify 'Orbstack cluster is running' || notify 'Orbstack cluster failed to come up'" &
            disown
        case development production
            aws-login
    end
end
