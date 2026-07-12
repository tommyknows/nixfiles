# Work Mac — home-manager: the macOS client profile + the work identity.
{...}: {
  imports = [
    ../../home/client.nix
    ../../home/work
  ];
  home.stateVersion = "22.11";
  # This machine's default commit-signing key (Secretive, per-device). The work
  # per-directory identity (~/Documents/work) is set inside home/work.
  programs.git.signing.key = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/6200f449acaa477b52befcbf60543848.pub";
}
