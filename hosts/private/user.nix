{pkgs, ...}: {
  imports = [../user.nix];

  home.packages = with pkgs; [
    yt-dlp
    vlc-bin
  ];

  programs.git.signing.key = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/b82a639650776679601851f8715d6bc6.pub";
}
