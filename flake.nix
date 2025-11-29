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
  in {
    darwinConfigurations = {
      work-laptop = nix-darwin.lib.darwinSystem {
        modules = [
          # Host configuration, non-home-manager stuff.
          ./hosts/work/work.nix
          ./hosts/system.nix
          # base home-manager to get it installed
          home-manager.darwinModules.home-manager
          # expression for all home-manager specific things.
          {
            home-manager = {
              useGlobalPkgs = true;
              users.ramon = import ./hosts/work/user.nix;
              extraSpecialArgs = {work_toggle = "enabled";};
            };
          }
        ];
        specialArgs = {
          inherit allowed-unfree-packages;
          unstable = inputs.unstable;
        };
      };
      private-laptop = nix-darwin.lib.darwinSystem {
        modules = [
          # Host configuration, non-home-manager stuff.
          ./hosts/private/private.nix
          ./hosts/system.nix
          # base home-manager to get it installed
          home-manager.darwinModules.home-manager
          # expression for all home-manager specific things.
          {
            home-manager = {
              useGlobalPkgs = true;
              extraSpecialArgs = {work_toggle = "disabled";};
              users.ramon = import ./hosts/private/user.nix;
            };
          }
        ];
        specialArgs = {
          inherit allowed-unfree-packages;
          unstable = inputs.unstable;
        };
      };
    };
  };
}
