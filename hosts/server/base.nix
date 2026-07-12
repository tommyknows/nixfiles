# Server base shared by the real host (default.nix) and the VM variant (vm.nix):
# the generic NixOS layer, the Emby overlay, on-disk layout, and host identity.
# Host-only bits (zfs, static IP, smartd, real sops) live in modules that only
# default.nix imports.
{...}: {
  imports = [../../system/nixos.nix]; # generic NixOS system layer (+ shared nixpkgs)

  # Expose the on-disk layout to every module as the arg `paths` (see paths.nix).
  _module.args.paths = import ./paths.nix;

  nixpkgs.overlays = [
    (final: _prev: {
      emby-server = final.callPackage ../../packages/emby-server {};
    })
  ];

  networking.hostName = "server";
  system.stateVersion = "26.05";
}
