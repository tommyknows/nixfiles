# Shared nixpkgs config for every host (the macOS systems and the server),
# imported by system/darwin and hosts/server. Only the genuinely-common bits
# live here; platform-specific nixpkgs (overlays) and Nix management (Determinate
# vs plain nix.settings) stay in their own modules.
#
# The unfree allowance is the union of what any host needs — permitting a package
# a given host never installs is harmless, and one list means a shared dependency
# (e.g. the home/vim plugins) can't be allowed on one host and forgotten on
# another.
{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      # client (macOS)
      "ngrok"
      "slack"
      "terraform"
      "claude-code"
      "crush"
      # shared home profile (home/vim plugins)
      "vim-bufkill"
      "vim-sandwich"
      # server
      "emby-server"
    ];
}
