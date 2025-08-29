{pkgs, ...}: {
  imports = [../user.nix];

  home.packages = with pkgs; [grpcurl];
  programs.git.signing.key =
"/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/ca4d9e3f5c1808f729c836bf0f343983.pub";
}
