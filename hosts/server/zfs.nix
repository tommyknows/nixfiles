# ZFS pools, scrub, and sanoid/syncoid snapshots+replication.
#
# Host-only — the VM does not import this; it fakes the /mnt tree with tmpfs.
# Every dataset named in `fileSystems` must already exist at boot, or its mount
# unit fails and the machine drops to emergency mode.
{paths, ...}: {
  boot.supportedFilesystems = ["zfs"];
  # Never force-import: a pool that didn't export cleanly means something is
  # wrong, and force-importing it risks data loss. Fail loudly instead.
  boot.zfs.forceImportRoot = false;
  # The backup pool's disk carries a stale linux_raid_member signature; keep
  # swraid off so it's never assembled as an mdraid member.
  boot.swraid.enable = false;

  networking.hostId = "deadbeef"; # required by ZFS; any 8 hex chars

  # Declare the service-critical datasets as fileSystems (zfsutil), NOT via
  # extraPools: this creates REAL mount units, pulls in the pool import, and lets
  # services order on the mounts (RequiresMountsFor). extraPools' zfs-mount.service
  # has no mount units, so a service starting early writes onto the empty
  # mountpoint and blocks the real mount ("directory not empty").
  fileSystems = let
    zfs = device: {
      inherit device;
      fsType = "zfs";
      options = ["zfsutil"];
    };
  in {
    ${paths.data} = zfs "tank";
    ${paths.media} = zfs "tank/media";
    ${paths.music} = zfs "tank/media/music";
    ${paths.pictures} = zfs "tank/media/pictures";
    ${paths.apps} = zfs "tank/apps";
    # Needs a real mount unit too, else services' RequiresMountsFor on it is a
    # silent no-op; also the replication target, so it must be mounted.
    ${paths.backup} = zfs "backup";
  };
  # Datasets not listed here still mount via zfs-mount.service after import; only
  # the ones services must order on need explicit mount units.

  services.zfs.autoScrub.enable = true;

  # ZED does nothing without a configured sendmail, so we don't rely on its mail;
  # disk-failure alerting goes through smartd's Telegram hook (monitoring.nix).
  # Add programs.msmtp here if you want zpool-event mails.

  services.sanoid = {
    enable = true;
    interval = "*-*-* 02,14:00:00"; # 2x/day
    templates.production = {
      hourly = 2;
      daily = 3;
      monthly = 0;
      autosnap = true;
      autoprune = true;
    };
    templates.backup = {
      hourly = 0;
      daily = 10;
      monthly = 3;
      autosnap = false;
      autoprune = true;
    };
    templates.apps = {
      # app state (the *arr SQLite DBs)
      hourly = 0;
      daily = 7;
      monthly = 0;
      autosnap = true;
      autoprune = true;
    };
    datasets."tank/media/music".useTemplate = ["production"];
    datasets."tank/media/pictures".useTemplate = ["production"];
    datasets."tank/apps".useTemplate = ["apps"];
    datasets."backup/media" = {
      useTemplate = ["backup"];
      recursive = true;
      processChildrenOnly = true;
    };
  };

  services.syncoid = {
    enable = true;
    interval = "*-*-01/2 03:00:00"; # every 2 days, 03:00
    commands."music" = {
      source = "tank/media/music";
      target = "backup/media/music";
      extraArgs = ["--no-sync-snap"];
    };
    commands."pictures" = {
      source = "tank/media/pictures";
      target = "backup/media/pictures";
      extraArgs = ["--no-sync-snap"];
    };
  };
}
