{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../darwin/system.nix
    ../darwin/user.nix
    ../darwin/autokbisw.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      home-manager
    ];
    shells = [pkgs.fish];
  };
}
