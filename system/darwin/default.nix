# Shared macOS system layer (nix-darwin), imported by both Mac hosts. The
# per-host system bits (dock apps, etc.) live in hosts/<host>/system.nix; the
# home-manager side lives in home/. This is the system-layer counterpart to
# home/default.nix.
{
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ../nixpkgs.nix # shared nixpkgs.config (unfree allowance)
    ./system.nix # macOS defaults (dock, finder, keyboard, touch-id sudo, fonts)
    ./user.nix # the ramon system user record (+ bluesnooze)
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
    customSettings."use-case-hack" = false;

    # Match the server's CLI nixpkgs resolution: point the `nixpkgs` registry
    # entry at FlakeHub's rolling, well-cached nixpkgs-weekly, so `nix run
    # nixpkgs#…` here hits the same tree it does on the server. The NixOS module
    # sets this automatically; the nix-darwin one leaves the registry empty, so
    # we set it by hand. Affects ad-hoc CLI only — system builds still use the
    # pinned flake inputs.
    registry.nixpkgs.to = {
      type = "tarball";
      url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    };
  };

  nixpkgs = {
    overlays = [
      # Expose the unstable channel as pkgs.unstable, inheriting this host's
      # nixpkgs config (so the shared unfree allowance applies there too).
      (_final: prev: {
        unstable = import unstable {
          inherit (prev.stdenv.hostPlatform) system;
          inherit (prev) config;
        };
      })
      # Track a few fast-moving tools from unstable.
      (final: _prev: {
        fish = final.unstable.fish;
        git-absorb = final.unstable.git-absorb;
        claude-code = final.unstable.claude-code;
        jujutsu = final.unstable.jujutsu;
      })
    ];
  };

  system.primaryUser = "ramon";
  environment = {
    systemPackages = with pkgs; [home-manager];
    shells = [pkgs.fish];
  };
}
