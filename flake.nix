{
  description = "Nix System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    unstable,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    system = "aarch64-darwin";
    # define all the unstable packages we use in a single place.
    unstablePackages = final: prev: {
      # add mappings for unstable packages here. For example:
      gopls = unstable.legacyPackages.${system}.gopls;
      golangci-lint = unstable.legacyPackages.${system}.golangci-lint;
      snyk = unstable.legacyPackages.${system}.snyk;
      fish = unstable.legacyPackages.${system}.fish;
      protobuf = unstable.legacyPackages.${system}.protobuf;
    };
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
              users.ramon = import ./hosts/user.nix;
              extraSpecialArgs = {work_toggle = "enabled";};
            };

            # overwrite / add some packages to pkgs from unstable.
            nixpkgs.overlays = [unstablePackages];
          }
        ];
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
              users.ramon = import ./hosts/user.nix;
            };

            # overwrite / add some packages to pkgs from unstable.
            nixpkgs.overlays = [unstablePackages];
          }
        ];
      };
    };
  };
}
