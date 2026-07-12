# home-manager for ramon on the server: the shared portable profile only
# (shell, editor, VCS, core CLI). No Mac/dev/cloud/GUI layers. This is what
# makes the server's shell feel like the Macs' instead of one-off.
{...}: {
  imports = [../../home/server.nix];
  home.stateVersion = "26.05";
}
