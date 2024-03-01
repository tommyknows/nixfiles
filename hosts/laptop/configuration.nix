{ config, pkgs, ... }: {
  imports = [
    ../../darwin/system.nix
    ../../darwin/user.nix
    ../../nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}

