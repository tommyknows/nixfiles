{
  description = "Nix System Config";

  #inputs = rec {
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    #home-manager.inputs.nixpkgs = nixpkgs;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # darwin
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    #nix-darwin.inputs.nixpkgs = nixpkgs;
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
          ./hosts/laptop/configuration.nix
          ./hosts/laptop/no-determinate.nix
          # base home-manager to get it installed
          home-manager.darwinModules.home-manager
          # expression for all home-manager specific things.
          {
            home-manager = {
              useGlobalPkgs = true;
              users.ramon = import ./hosts/laptop/home.nix;
              extraSpecialArgs = {work_toggle = "enabled";};
            };

            # overwrite / add some packages to pkgs from unstable.
            nixpkgs.overlays = [unstablePackages];
          }
        ];
      };
      Ramons-MacBook-Air = nix-darwin.lib.darwinSystem {
        modules = [
          # Host configuration, non-home-manager stuff.
          ./hosts/laptop/configuration.nix
          ./hosts/laptop/determinate.nix
          # base home-manager to get it installed
          home-manager.darwinModules.home-manager
          # expression for all home-manager specific things.
          {
            home-manager = {
              useGlobalPkgs = true;
              extraSpecialArgs = {work_toggle = "disabled"; };
              users.ramon = import ./hosts/laptop/home.nix;
            };

            # overwrite / add some packages to pkgs from unstable.
            nixpkgs.overlays = [unstablePackages];
          }
        ];
      };
    };
  };
}
