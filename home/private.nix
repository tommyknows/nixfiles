# Private (personal) identity home profile. Composed by the private host
# alongside home/client.nix. The sibling of home/work.nix.
{pkgs, ...}: {
  home.packages = with pkgs; [
    yt-dlp
    vlc-bin
  ];
}
