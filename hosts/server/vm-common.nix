# Shared VM adaptations: the service modules plus the tweaks that make them run
# in a throwaway VM with no real disks or secrets. Imported by both the
# interactive VM (vm.nix) and the automated integration test (test.nix), so the
# two stay in sync. Neither the real host nor these consumers set a root
# filesystem here — vm.nix adds one for interactive use; the test harness
# provides its own.
{
  lib,
  pkgs,
  paths,
  ...
}: {
  imports = [
    ./base.nix
    ./nginx.nix
    ./arrs.nix
    ./emby.nix
    ./opencloud.nix
    ./samba.nix
    ./dns.nix
  ];

  # No decryption key here, so the service modules' sops references can't
  # resolve to real values:
  #   - sops-install-secrets fails, /run/secrets stays empty (expected)
  #   - acme can't read its token, so nginx falls back to its self-signed cert
  #     and acme-order-renew fails (expected)
  #   - the samba password seeder becomes a no-op (smbd still starts)
  #   - transmission won't start without a credentials file, so hand it a dummy
  # server.yaml is named only to give sops a valid source; it's never decrypted.
  sops.defaultSopsFile = ../../secrets/server.yaml;
  services.transmission.credentialsFile =
    lib.mkForce (pkgs.writeText "vm-rpc.json" ''{"rpc-password":"vmdummy"}'');
  systemd.services.samba-setup-passwords.script = lib.mkForce "true";

  # OpenCloud is only useful with its real state and is heavy to start cold, so
  # it's disabled here. Its vhost stays defined (cloud.* just 502s).
  services.opencloud.enable = lib.mkForce false;

  # Stand in for the ZFS datasets with tmpfs so the mount units services order on
  # exist and state is writable (throwaway). Root fs is intentionally not set.
  fileSystems = let
    tmpfs = {
      device = "tmpfs";
      fsType = "tmpfs";
    };
  in {
    ${paths.data} = tmpfs;
    ${paths.media} = tmpfs;
    ${paths.apps} = tmpfs;
    ${paths.backup} = tmpfs;
  };
  systemd.tmpfiles.rules = let
    tx = paths.appDir "transmission";
  in [
    "d ${paths.apps} 0775 root share -"
    "d ${paths.appDir "radarr"} 0755 torrent share -"
    "d ${paths.appDir "sonarr"} 0755 torrent share -"
    "d ${paths.appDir "lidarr"} 0755 torrent share -"
    "d ${paths.appDir "jackett"} 0755 torrent share -"
    "d ${tx} 0755 torrent share -"
    "d ${tx}/.config 0755 torrent share -"
    "d ${tx}/.config/transmission-daemon 0755 torrent share -"
    "d ${paths.appDir "emby"} 0755 emby emby -"
    "d ${paths.media} 0775 torrent share -"
    "d ${paths.music} 0775 torrent share -"
    "d ${paths.downloads} 0775 torrent share -"
    "d ${paths.downloads}/transmission 0775 torrent share -"
    "d ${paths.dataBackup} 0775 root share -"
    "d ${paths.dataBackup}/denise 0775 ramon share -"
    "d ${paths.backup}/denise-videos 0775 root share -"
  ];

  # Tools the checklist/tests invoke inside the guest (smbclient ships with samba).
  environment.systemPackages = with pkgs; [dig curl samba];

  # Exercise auth.nix's "TOTP required for sudo" policy in the integration test.
  # The real host seeds users.oath from sops; here we write a known, throwaway
  # seed directly so the test can compute valid codes. This is the RFC 6238 test
  # seed ("12345678901234567890") in hex — NOT a secret. auth.nix itself isn't
  # imported here (it pulls in sops-only root-password), so its policy is
  # restated; keep the two in sync.
  security.pam.oath = {
    enable = true;
    digits = 6;
    window = 3;
    usersFile = "/var/lib/oath/users.oath";
  };
  security.pam.services.sudo = {
    oathAuth = true;
    allowNullPassword = true;
  };
  system.activationScripts.oathTestSeed.text = ''
    mkdir -p /var/lib/oath
    printf '%s\n' 'HOTP/T30/6 ramon - 3132333435363738393031323334353637383930' > /var/lib/oath/users.oath
    chmod 600 /var/lib/oath/users.oath
  '';
}
