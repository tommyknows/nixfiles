{
  description = "Nix System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

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
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    allowed-unfree-packages = [
      "ngrok"
      "slack"
      "terraform"
      "claude-code"
      "crush"
      "vim-bufkill"
      "vim-sandwich"
    ];

    # define the hosts and extra modules we want to include.
    hosts = {
      work = [./work/default.nix];
      private = [];
    };
  in {
    darwinConfigurations =
      builtins.mapAttrs (
        hostname: extraModules:
          nix-darwin.lib.darwinSystem {
            modules = [
              {nixpkgs.hostPlatform = "aarch64-darwin";}
              # Override fish to use unstable and provide 'sphinx' as a build-input to ensure docs are being built.
              {
                nixpkgs.overlays = [
                  (final: _prev: {
                    fish = final.unstable.fish;
                    git-absorb = final.unstable.git-absorb;
                    claude-code = final.unstable.claude-code;
                  })
                ];
              }
              # Host configuration, non-home-manager stuff.
              (./hosts + "/${hostname}/${hostname}.nix")
              ./hosts/system.nix
              # base home-manager to get it installed
              home-manager.darwinModules.home-manager
              # expression for all home-manager specific things.
              {
                home-manager = {
                  useGlobalPkgs = true;
                  users.ramon = {
                    imports = [(./hosts + "/${hostname}/user.nix")] ++ extraModules;
                  };
                  extraSpecialArgs =
                    {inherit hostname;}
                    // (
                      if hostname == "work"
                      then {
                        ic = inputs.ic;
                        infracost_cli = inputs.infracost_cli;
                        cloud-data = inputs.cloud-data;
                        internal-skills = inputs.internal-skills;
                      }
                      else {}
                    );
                };
              }
            ];
            specialArgs = {
              inherit allowed-unfree-packages;
              unstable = inputs.unstable;
            };
          }
      )
      hosts;
  };
}
