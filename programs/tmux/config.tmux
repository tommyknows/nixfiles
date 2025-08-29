set -g focus-events on

unbind x
bind q select-pane -L
bind j select-pane -D
bind k select-pane -U
bind x select-pane -R
bind h kill-pane

# https://github.com/christoomey/vim-tmux-navigator/issues/417
#is_vim="ps -o tty= -o state= -o comm= | \
#    grep -iqE '^#{s|/dev/||:pane_tty} +[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | \
grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
bind-key -n C-q if-shell "$is_vim" "send-keys C-q" "select-pane -L"
bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
bind-key -n C-x if-shell "$is_vim" "send-keys C-x" "select-pane -R"

bind-key -T copy-mode-vi C-q select-pane -L
bind-key -T copy-mode-vi C-j select-pane -D
bind-key -T copy-mode-vi C-k select-pane -U
bind-key -T copy-mode-vi C-x select-pane -R
bind-key -T copy-mode-vi C-\\ select-pane -l

bind-key -T edit-mode-vi Up send-keys -X history-up
bind-key -T edit-mode-vi Down send-keys -X history-down
set-option -g history-limit 100000

set-option -g renumber-windows on

set-option -g mouse on

bind -r Q resize-pane -L 2
bind -r J resize-pane -D 2
bind -r K resize-pane -U 2
bind -r X resize-pane -R 2

bind-key -n C-S-Left swap-window -t -1
bind-key -n C-S-Right swap-window -t +1

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

bind Tab last-window

bind-key [ copy-mode
bind-key ] paste-buffer

bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe "reattach-to-user-namespace pbcopy"
bind-key -T copy-mode-vi Enter
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe "reattach-to-user-namespace pbcopy"

set-option -g status-interval 1

setw -g monitor-activity off
set -g visual-activity on

set-option -g set-titles on
set-option -g set-titles-string '#S'

# Airline
set -g status-bg "#1f292d"
set -g status-justify "left"
set -g status-left-length "100"
set -g status "on"
set -g status-right-length "100"
setw -g window-status-separator ""

set-option -g status-interval 5
set-option -g automatic-rename on
set-option -g automatic-rename-format '#(/Users/ramon/.nixpkgs/programs/tmux/title.sh "#{pane_current_path}") #{pane_current_command}'

set -g pane-border-style fg=black
set -g pane-active-border-style fg=white,bg=default

unbind-key C-l
unbind-key C-h

set -as terminal-features ",*:RGB"
# Nix automatically installs tmux-sensible, which installs the reattach-to-user-namespace plugin. Something (likely
# nix?) sets the `default-command` to something like "reattach-to-user-namespace -l zsh", which overwrites the shell...
# This unsets the option, so that we don't have the default-command anymore. reattach-to-user-namespace isn't needed
# anymore in more recent versions of tmux.
set -gu default-command
