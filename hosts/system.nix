{
  config,
  pkgs,
  lib,
  allowed-unfree-packages,
  unstable,
  nix-ai-tools,
  ...
}: {
  imports = [
    ../darwin/system.nix
    ../darwin/user.nix
  ];

  # disable nix as it's installed and managed through determinate.
  nix.enable = false;

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
        nix-ai-tools = nix-ai-tools.packages.${prev.stdenv.hostPlatform.system};
      })
    ];
  };

  system.primaryUser = "ramon";

  environment = {
    systemPackages = with pkgs; [home-manager];
    shells = [pkgs.fish];
  };
}
