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

  # Configure Determinate Nix declaratively via its nix-darwin module, which
  # reconciles config on switch. We use the Nixpkgs VM builder
  # (darwin.linux-builder) to build aarch64-linux / x86_64-linux derivations —
  # e.g. the NixOS server config — on this Mac without a remote builder.
  #
  # TODO: switch to Determinate's *native* Linux builder (Apple Virtualization,
  # lower overhead) once it's granted on our FlakeHub account. It's a gated
  # gradual rollout — access requested via support@determinate.systems on
  # 2026-07-12 (docs: https://docs.determinate.systems/determinate-nix/linux-builder/).
  # Until the `native-linux-builder` feature shows up in `determinate-nixd
  # version`, `builder.state = "enabled"` is silently ignored (external-builders
  # stays []). When granted, replace nixosVmBasedLinuxBuilder below with:
  #   determinateNixd.builder.state = "enabled";
  determinateNix = {
    enable = true;
    nixosVmBasedLinuxBuilder.enable = true;
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
