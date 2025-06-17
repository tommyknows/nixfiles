{pkgs, ...}: {
  nix = {
    # TODO: still needed?
    # https://github.com/NixOS/nix/issues/11002
    settings.sandbox = false;

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };
}
