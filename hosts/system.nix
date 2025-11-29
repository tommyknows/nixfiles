{
  config,
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
  
  nixpkgs = {
    # Apply allowUnfreePredicate to both main nixpkgs and unstable
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed-unfree-packages;
    
    # Configure unstable with the same unfree predicate
    overlays = [
      (final: prev: {
        unstable = import unstable {
          system = prev.system;
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed-unfree-packages;
        };
      })
    ];
  };

  system.primaryUser = "ramon";

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    shells = [pkgs.fish];
  };
}
