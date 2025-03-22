{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      colors.primary = {
        background = "0x263137";
        foreground = "0xeceef0";
      };
      colors.normal = {
        black = "0x263137";
        blue = "0x40c4fe";
        cyan = "0x64fcda";
        green = "0x69efad";
        magenta = "0xfe3f80";
        red = "0xfe5151";
        white = "0xfffefe";
        yellow = "0xffd640";
      };
      colors.bright = {
        black = "0xb0bec4";
        blue = "0x80d7fe";
        cyan = "0xa7fdeb";
        green = "0xb9f5c9";
        magenta = "0xfe7faa";
        red = "0xfe897f";
        white = "0xfffefe";
        yellow = "0xffe47e";
      };
      colors.cursor = {
        cursor = "#edeede";
        text = "#000000";
      };
      colors = {
        draw_bold_text_with_bright_colors = false;
      };
      cursor = {
        style = {
          shape = "Block";
          blinking = "Off";
        };
      };
      font = {
        size = 14;
      };
      # fonts are installed through the system (darwin/system.nix)
      font.bold = {
        family = "SauceCodePro Nerd Font";
        style = "SemiBold";
      };
      font.normal = {
        family = "SauceCodePro Nerd Font";
        style = "Regular";
      };
      mouse = {
        hide_when_typing = true;
      };
      window = {
        decorations = "none";
        dynamic_title = true;
        opacity = 0.92;
        startup_mode = "Windowed";
        option_as_alt = "Both";
      };
      terminal = {
        shell = {
          program = "${pkgs.fish}/bin/fish";
        };
      };
    };
  };
  # to get 24-Bit colors to work, we need to set this.
  # TODO: does not seem to be necessary
  #  programs.tmux.extraConfig = ''
  #    set -ag terminal-overrides ",alacritty:RGB,xterm-256color-italic:RGB"
  #'';
}
