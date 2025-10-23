{pkgs, ...}: {
  imports = [../user.nix];

  home.packages = with pkgs; [
    grpcurl
    #tailscale
  ];
  programs.git.signing.key = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/6200f449acaa477b52befcbf60543848.pub";
}
