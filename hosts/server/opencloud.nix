# OpenCloud: service, user, secret, and public vhost.
#
# The identity-bearing config and data (opencloud.yaml, IDM store, storage) are
# provided out of band under stateDir + /etc/opencloud, not generated here — so
# only behaviour/URLs/bindings live below. The mkIf guards throughout are because
# the VM disables opencloud, and a bare user/secret without the module enabled
# would trip assertions.
{
  config,
  lib,
  paths,
  ...
}: {
  # owner=opencloud needs the user, which only exists when the module is on.
  sops.secrets."opencloud-env" = lib.mkIf config.services.opencloud.enable {owner = "opencloud";};

  services.opencloud = {
    enable = true;
    url = "https://cloud.ramonr.ch";
    address = "127.0.0.1";
    port = 9200;
    stateDir = "${paths.appDir "opencloud"}/data";
    environment.OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD = "false";
    environmentFile = config.sops.secrets."opencloud-env".path;
    settings = {}; # empty so the module runs its init oneshot instead of expecting inline config
  };

  # uid pinned so opencloud owns its state dir (owner perms suffice). If the
  # module ever ignores the override, `chown -R 1050 stateDir` once.
  users.users.opencloud = lib.mkIf config.services.opencloud.enable {
    uid = 1050;
    extraGroups = ["share"];
  };
  systemd.services.opencloud = lib.mkIf config.services.opencloud.enable {
    unitConfig.RequiresMountsFor = [paths.apps];
  };

  services.nginx.virtualHosts."cloud.ramonr.ch" = {
    useACMEHost = "ramonr.ch";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9200"; # upstream is plain HTTP (OC_INSECURE)
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 0;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
      '';
    };
  };
}
