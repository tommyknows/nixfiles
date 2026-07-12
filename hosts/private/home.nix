# Private Mac — home-manager: the macOS client profile + the private identity.
{...}: {
  imports = [
    ../../home/client.nix
    ../../home/private.nix
  ];
  home.stateVersion = "22.11";
  # This machine's default commit-signing key (Secretive, per-device).
  programs.git.signing.key = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/b82a639650776679601851f8715d6bc6.pub";
}
