{
  description = "Nix System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixOS branch for the homeserver (`nixosConfigurations.server`). Same 26.05
    # release as the Darwin hosts, separate branch — the normal split. Darwin
    # stays on nixpkgs-26.05-darwin above; nothing here perturbs it.
    nixos.url = "github:nixos/nixpkgs/nixos-26.05";

    # Secrets for the server (sops-nix). Follows the server's nixpkgs so we don't
    # drag a second full nixpkgs tree into the closure.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixos";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Determinate Nix's own nix-darwin module — lets us configure Determinate
    # (incl. the native Linux builder) declaratively instead of hand-editing
    # /etc/nix/nix.custom.conf. Requires nix.enable = false (set in system.nix).
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    ic = {
      url = "git+ssh://git@github.com/infracost/ic";
      flake = false;
    };
    infracost_cli = {
      url = "git+ssh://git@github.com/infracost/cli";
      flake = false;
    };
    cloud-data = {
      url = "git+ssh://git@github.com/infracost/cloud-data?ref=refs/tags/api/gen/go/v0.0.29";
      flake = false;
    };
    internal-skills = {
      url = "git+ssh://git@github.com/infracost/internal-skills";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: {
    # macOS hosts. Each hosts/<host>/ has a thin system.nix + home.nix that
    # compose the shared layers: system/darwin (nix-darwin) and home/client
    # (home-manager) + an identity profile (home/private | home/work).
    darwinConfigurations =
      nixpkgs.lib.genAttrs ["private" "work"] (
        hostname:
          nix-darwin.lib.darwinSystem {
            specialArgs = {
              unstable = inputs.unstable;
            };
            modules = [
              {nixpkgs.hostPlatform = "aarch64-darwin";}
              ./system/darwin # shared macOS system layer
              (./hosts + "/${hostname}/system.nix") # per-host system
              inputs.determinate.darwinModules.default
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.users.ramon.imports = [(./hosts + "/${hostname}/home.nix")];
                # Work's home profile builds private CLIs from these inputs.
                home-manager.extraSpecialArgs =
                  {inherit hostname;}
                  // (
                    if hostname == "work"
                    then {inherit (inputs) ic infracost_cli cloud-data internal-skills;}
                    else {}
                  );
              }
            ];
          }
      );

    # Homeserver. `server` is the real x86_64 target; `server-vm` is the aarch64
    # VM variant for local validation on the Mac — it imports only the
    # hardware-independent service modules.
    nixosConfigurations = {
      server = inputs.nixos.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/server
          # Determinate Nix, matching the Macs. Unlike the nix-darwin module
          # (which needs nix.enable = false to hand over completely), the NixOS
          # module layers on top of the stock nix-daemon: it swaps nix.package
          # for Determinate's build and overrides the daemon's ExecStart to
          # determinate-nixd, so our nix.settings still apply (written to
          # nix.custom.conf, included by the Determinate-managed nix.conf).
          # server-vm and the checks test stay on stock nix on purpose —
          # throwaway VM / CI want no determinate-nixd socket or FlakeHub registry.
          inputs.determinate.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {hostname = "server";};
            home-manager.users.ramon = import ./hosts/server/home.nix;
          }
        ];
      };

      server-vm = inputs.nixos.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/server/vm.nix
          inputs.sops-nix.nixosModules.sops
        ];
      };
    };

    # `nix run .#server-vm` on the Mac: qemu runs natively (hvf), the guest
    # closure is built on the aarch64-linux builder. Throwaway qcow2 in cwd.
    packages.aarch64-darwin.server-vm =
      self.nixosConfigurations.server-vm.config.system.build.vm;

    # Automated integration test of the homeserver services (headless). Exposed
    # for both Linux systems; run it wherever a builder with the `nixos-test`
    # feature exists — natively on the x86_64 box:
    #   nix build .#checks.x86_64-linux.server-services -L
    # (The Mac's VM-based builder doesn't advertise `nixos-test`, and nested KVM
    # for it needs an M3+ host, so run this on real Linux.)
    checks = let
      serverServicesTest = system:
        inputs.nixos.legacyPackages.${system}.testers.runNixOSTest {
          name = "server-services";
          # Let each node build pkgs from its own nixpkgs config/overlays
          # (base.nix needs the emby overlay + unfree predicate); the default
          # read-only pkgs forbids that.
          node.pkgsReadOnly = false;
          nodes = {
            server = {
              imports = [
                inputs.sops-nix.nixosModules.sops
                ./hosts/server/vm-common.nix
              ];
              # vlan 1 (LAN, allowed) + vlan 2 (used by `outsider` to test deny).
              virtualisation.vlans = [1 2];
            };
            outsider = {pkgs, ...}: {
              virtualisation.vlans = [2];
              environment.systemPackages = [pkgs.curl];
            };
          };
          testScript = builtins.readFile ./hosts/server/test-script.py;
        };
    in {
      aarch64-linux.server-services = serverServicesTest "aarch64-linux";
      x86_64-linux.server-services = serverServicesTest "x86_64-linux";
    };
  };
}
