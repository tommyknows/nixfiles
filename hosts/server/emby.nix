# Emby: native custom package (no container), its state, and its public vhost.
# HW transcoding via the iGPU — Emby bundles the Intel VAAPI/QSV stack, so the
# host only needs i915 (default) + /dev/dri access via the video/render groups.
{
  paths,
  pkgs,
  ...
}: {
  users.groups.emby = {};
  users.users.emby = {
    # uid pinned so emby owns its existing state dir; share group for media read.
    uid = 1030;
    group = "emby";
    extraGroups = ["share"];
    isSystemUser = true;
    # TODO: if any state files are group-owned under a specific gid, pin
    # users.groups.emby.gid to match (check with `stat -c %g` on the data dir).
  };

  systemd.services.emby = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    unitConfig.RequiresMountsFor = [paths.apps paths.media paths.backup];
    environment.EMBY_DATA = paths.appDir "emby";
    serviceConfig = {
      ExecStart = "${pkgs.emby-server}/bin/emby-server";
      User = "emby";
      Group = "emby";
      SupplementaryGroups = ["video" "render"]; # /dev/dri for QSV
      Restart = "on-failure";
      SuccessExitStatus = 3; # emby's restart-request exit code
    };
  };

  services.nginx.virtualHosts."media.ramonr.ch" = {
    useACMEHost = "ramonr.ch";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
    };
  };
}
