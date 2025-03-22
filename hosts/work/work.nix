{pkgs, ...}: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix = {
    # TODO: still needed?
    # https://github.com/NixOS/nix/issues/11002
    settings.sandbox = false;

    # TODO: still needed?
    configureBuildUsers = true;
    nrBuildUsers = 32;

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };
}
