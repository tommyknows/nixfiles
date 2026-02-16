{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    terminal = "xterm-256color";
    shell = "${pkgs.fish}/bin/fish";
    sensibleOnTop = true;
    escapeTime = 1;
    baseIndex = 1;
    extraConfig =
      builtins.replaceStrings
      ["<titlescript.sh>"]
      ["${pkgs.writeShellScript "tmux-title" (builtins.readFile ./title.sh)}"]
      (builtins.readFile ./config.tmux);
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = battery;
        extraConfig = ''
          set -g status-left "#[fg=#ffffff,bg=#506E79,bold] #S #[fg=#506E79,bg=#1f292d]"
          setw -g window-status-format "#[fg=#b0bec5,bg=#1f292d] #I #W "
          #setw -g window-status-current-format "#[fg=colour67,bg=colour16,nobold,nounderscore,noitalics]#[fg=colour253,bg=colour16] #I #[fg=colour253,bg=colour16] #W #[fg=colour16,bg=colour67,nobold,nounderscore,noitalics]"
          setw -g window-status-current-format "#[fg=#1f292d,bg=#b0bec5]#[fg=#1f292d,bg=#b0bec5,nobold,nounderscore,noitalics] #I #W #[fg=#b0bec5,bg=#1f292d]"

          # indicate whether Prefix has been captured + time in the right-status area
          #set -g status-right "#[fg=#b0bec5,bg=#1f292d]#[fg=#1f292d,bg=#b0bec5] #{battery_icon} #{battery_percentage} | #{cpu_percentage} #[fg=#506E79,bg=#b0bec5]#[fg=#ffffff,bg=#506E79] %H:%M #[fg=#fd9720,bg=#506E79]#[fg=#1f292d,bg=#fd9720] %h %d #[fg=#e73c50,bg=#fd9720]#[fg=#ffffff,bold,bg=#e73c50]#{?client_prefix, TRIGGERED ,}"

          set -g status-right "#[fg=#b0bec5,bg=#1f292d]#[fg=#1f292d,bg=#b0bec5] #{battery_icon} #{battery_percentage} | #[fg=#506E79,bg=#b0bec5]#[fg=#ffffff,bg=#506E79] %H:%M #[fg=#fd9720,bg=#506E79]#[fg=#1f292d,bg=#fd9720] %h %d #[fg=#e73c50,bg=#fd9720]#[fg=#ffffff,bold,bg=#e73c50]#{?client_prefix, TRIGGERED ,}"
        '';
      }
      yank
      {
        plugin = resurrect;
        extraConfig = "
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-capture-pane-contents 'on'
";
      }
    ];
  };
}
