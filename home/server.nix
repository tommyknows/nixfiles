# Server (NixOS) home-manager profile: the shared base, nothing Mac-specific.
# Imported by hosts/server/home.nix. Server-only user config (if any ever
# arises) layers on here — the symmetric counterpart to client.nix.
{...}: {
  imports = [./default.nix];
}
