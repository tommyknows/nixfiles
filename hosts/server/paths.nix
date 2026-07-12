# Single source of truth for the on-disk layout. Injected as the module arg
# `paths` (see base.nix: `_module.args.paths`), so any module can take
# `{ paths, ... }:` and use `paths.music`, `paths.appDir "emby"`, etc. — no
# import boilerplate, no hand-typed /mnt strings scattered across modules.
#
# ZFS *dataset* names (tank/media/music) are a separate namespace and stay
# literal in zfs.nix; this file is only about mountpoints/directories.
rec {
  # tank pool (mounted at /mnt/data)
  data = "/mnt/data";
  apps = "${data}/apps"; # app state (tank/apps)
  media = "${data}/media"; # tank/media
  music = "${media}/music";
  pictures = "${media}/pictures";
  downloads = "${media}/downloads";
  dataBackup = "${data}/backup"; # tank's backup dataset — NOT the backup pool

  # backup pool (mounted at /mnt/backup) — distinct from dataBackup above
  backup = "/mnt/backup";

  # app state lives at /mnt/data/apps/<app>
  appDir = name: "${apps}/${name}";
}
