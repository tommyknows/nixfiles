# Samba + Avahi. NFS was rejected (poor macOS support). Passwords can't be
# declared (the passdb is state), so a oneshot seeds them from sops before smbd.
{
  config,
  paths,
  pkgs,
  ...
}: {
  sops.secrets."smb-ramon" = {}; # read by the seed oneshot (root)
  sops.secrets."smb-denise" = {};

  # denise exists only as a Samba credential (no login). uid/gid pinned to match
  # the ownership of her existing backup-share files so no chown is needed.
  users.users.denise = {
    isSystemUser = true;
    uid = 1012;
    group = "share";
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server smb encrypt" = "desired";
        "vfs objects" = "catia fruit streams_xattr"; # macOS compat, avoids ._ files
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "no";
        "hosts allow" = "192.168.1. 100. 127.";
      };
      backup = {
        path = "${paths.dataBackup}/denise"; # tank's backup dataset
        "valid users" = "ramon denise";
        writable = "yes";
      };
      videos = {
        path = "${paths.backup}/denise-videos"; # backup POOL, not dataBackup
        "read only" = "yes";
        browseable = "yes";
        "guest ok" = "yes";
      };
      music = {
        path = paths.music;
        "valid users" = "ramon";
        writable = "yes";
      };
    };
  };

  services.avahi = {
    enable = true; # Finder discovery
    publish.enable = true;
    publish.userServices = true;
  };

  # Seed the passdb from secrets before smbd starts. smbpasswd -a needs the unix
  # user to exist (ramon, denise both do). Idempotent — re-adding resets the pw.
  systemd.services.samba-setup-passwords = {
    description = "Seed Samba passwords from secrets";
    wantedBy = ["multi-user.target"];
    before = ["samba-smbd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      seed() { printf '%s\n%s\n' "$(cat "$2")" "$(cat "$2")" | ${pkgs.samba}/bin/smbpasswd -s -a "$1"; }
      seed ramon ${config.sops.secrets."smb-ramon".path}
      seed denise ${config.sops.secrets."smb-denise".path}
    '';
  };
}
