{
  description = "Nix System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    system = "aarch64-darwin";

    allowed-unfree-packages = [
      "ngrok"
      "slack"
      "terraform"
      "crush"
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
                  extraSpecialArgs = {
                    inherit hostname;
                  };
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
