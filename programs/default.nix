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
      ./vim
      ./git
      ./fish/default.nix
      ./tmux
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
    ssh = {
      enable = true;
      extraConfig = "IdentityAgent /Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
  };
}
