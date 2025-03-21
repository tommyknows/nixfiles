{pkgs, ...}: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # allow closed source packages as well.
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # https://github.com/NixOS/nix/issues/11002
  nix.settings.sandbox = false;

  nix.configureBuildUsers = true;
  nix.nrBuildUsers = 32;

  environment.shells = [pkgs.fish];
}
