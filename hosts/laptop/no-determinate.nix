{pkgs, ...}: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # https://github.com/NixOS/nix/issues/11002
  nix.settings.sandbox = false;

  # TODO: still needed?
  nix.configureBuildUsers = true;
  nix.nrBuildUsers = 32;
}
