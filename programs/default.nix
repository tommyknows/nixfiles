{
  pkgs,
  unstable,
  config,
  ...
}: {
  imports = [
    ./alacritty.nix
    ./autokbisw.nix
    ./fish
    ./git
    ./tmux
    ./vim
  ];

  programs = {
    go = {
      enable = true;
      env = {
        GOPATH = "${config.home.homeDirectory}/Documents/go";
        # Bug in Go: https://github.com/golang/go/issues/58218
        GOFLAGS = "-buildvcs=false";
      };
    };
    lsd = {
      enable = true;
      settings = {
        sorting = {dir-grouping = "first";};
      };
    };
    fzf = {
      enable = true;
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
      enableDefaultConfig = false;
      matchBlocks."*" = {
        forwardAgent = false;
        identityAgent = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      };
    };
  };
}
