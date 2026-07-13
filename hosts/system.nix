{
  pkgs,
  lib,
  allowed-unfree-packages,
  unstable,
  ...
}: {
  imports = [
    ../darwin/system.nix
    ../darwin/user.nix
  ];

  # disable nix as it's installed and managed through determinate.
  nix.enable = false;

  # We use Determinate's *native* Linux builder (Apple Virtualization, lower
  # overhead than a full NixOS VM) to build aarch64-linux / x86_64-linux
  # derivations — e.g. the NixOS server config — on this Mac without a remote
  # builder.
  determinateNix = {
    enable = true;
    determinateNixd.builder.state = "enabled";
  };

  nixpkgs = {
    # Apply allowUnfreePredicate to both main nixpkgs and unstable
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed-unfree-packages;

    # Configure unstable with the same unfree predicate
    overlays = [
      (final: prev: {
        unstable = import unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed-unfree-packages;
        };
      })
    ];
  };

  system.primaryUser = "ramon";

  environment = {
    systemPackages = with pkgs; [home-manager];
    shells = [pkgs.fish];
  };
}
