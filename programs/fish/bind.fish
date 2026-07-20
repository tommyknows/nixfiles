# alt-o: kubectl resource picker.  alt-r: ripgrep results into the commandline.
bind \eo _kubectl_fzf_autocomplete
bind -M insert \eo _kubectl_fzf_autocomplete
bind \er _rzf
bind -M insert \er _rzf

# alt-c ("changes"): pick a jj change / git commit and insert its id at the cursor.
# Overrides fzf's alt-c cd-widget (directory search lives on ctrl-o via fzf.fish).
bind alt-c _pick_commit_widget
bind -M insert alt-c _pick_commit_widget

bind -M insert alt-backspace backward-kill-word
# Fish 4.0 changed the behaviour of alt-left and right to travel
# full "tokens" instead of words.
# > alt-left and alt-right will now move by one argument (which may
# > contain quoted spaces), not just one word like ctrl-left and
# > ctrl-right do.
# ctrl-left and right are unusable on Mac because they're used to
# switch desktops, so we change the behaviour back.
bind -M insert alt-left prevd-or-backward-word
bind -M insert alt-right nextd-or-forward-word
