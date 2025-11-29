{
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ./alacritty
    ./fish/default.nix
    ./git
    ./tmux
    ./vim
  ];

  programs = {
    go = {
      enable = true;
      goPath = "Documents/go";
      # TODO: unreleased; should be in the next home-manager release.
      # In the meantime I've set this manually with `go env -w GOFLAGS="-buildvcs=false"`
      #env = {
      #  # Bug in Go: https://github.com/golang/go/issues/58218
      #  GOFLAGS = "-buildvcs=false";
      #};
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
      extraConfig = "IdentityAgent /Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
  };
}
