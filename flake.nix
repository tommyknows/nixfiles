{
  description = "Nix System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # darwin
    nix-darwin.url = "github:LnL7/nix-darwin";
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
      alacritty = unstable.legacyPackages.${system}.alacritty;
      go_1_22 = unstable.legacyPackages.${system}.go_1_22;
      gopls = unstable.legacyPackages.${system}.gopls;
      snyk = unstable.legacyPackages.${system}.snyk;
    };
  in {
    darwinConfigurations = {
      work-laptop = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Host configuration, non-home-manager stuff.
          ./hosts/laptop/configuration.nix
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
    };
  };
}
