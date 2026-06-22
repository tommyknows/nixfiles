{config, ...}: {
  imports = [
    ./alacritty.nix
    ./autokbisw.nix
    ./claude
    ./fish
    ./git
    ./jujutsu
    ./packages.nix
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
        # --hidden makes rg descend into dotfiles/dirs, so re-exclude the VCS
        # stores it would otherwise search (rg only skips .git by default, and
        # only without --hidden). .jj is jj's equivalent.
        "--glob"
        "  !.git"
        "--glob"
        "  !.jj"
      ];
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        ForwardAgent = false;
        IdentityAgent = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      };
    };
  };
}
