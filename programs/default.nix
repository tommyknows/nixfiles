{
  work_toggle,
  pkgs,
  unstable,
  ...
}: let
  work = {
    "enabled" = [(import ../work/default.nix)];
    "disabled" = [];
  };
in {
  imports =
    [
      ./alacritty
      ./fish/default.nix
      ./git
      ./tmux
      ./vim
    ]
    ++ (work.${work_toggle} or []);

  programs = {
    go = {
      enable = true;
      package = pkgs.go_1_22;
      goPath = "Documents/go";
    };
    lsd = {
      enable = true;
      settings = {
        sorting = {dir-grouping = "first";};
      };
    };
    fzf = {
      enable = true;
      defaultCommand = "rg";
    };
    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob"
        "  !.git"
      ];
    };
    ssh = {
      enable = true;
      extraConfig = "IdentityAgent /Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
  };
}
