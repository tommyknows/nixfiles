{pkgs, ...}: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # allow closed source packages as well.
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.settings.sandbox = true;

  nix.configureBuildUsers = true;
  nix.nrBuildUsers = 32;

  environment.loginShell = "${pkgs.fish}/bin/fish";
  environment.shells = [pkgs.fish];
}
