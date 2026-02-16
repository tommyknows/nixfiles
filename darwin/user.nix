{pkgs, ...}: {
  imports = [
    ./bluesnooze.nix
  ];
  users.users.ramon = {
    createHome = true;
    home = "/Users/ramon";
    shell = pkgs.fish;
    # TODO: we should be able to use programs.fish.enable = true; instead,
    # but we set this already in programs/fish/default.nix and Nix doesn't care?
    ignoreShellProgramCheck = true;
  };
}
