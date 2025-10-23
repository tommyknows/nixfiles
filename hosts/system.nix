{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../darwin/system.nix
    ../darwin/user.nix
  ];

  # disable nix as it's installed and managed through determinate.
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;

  system.primaryUser = "ramon";

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    shells = [pkgs.fish];
  };
}
