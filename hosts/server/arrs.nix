# Download stack: radarr, sonarr, lidarr, jackett, transmission — each with its
# service, LAN vhost, and secret together. The whole stack runs as one user
# (torrent:share) owning both app state and the media files, so a single uid/gid
# reaches everything without per-service permission juggling. State lives on
# tank/apps (via dataDir/home) rather than /var/lib so sanoid snapshots cover it.
{
  config,
  paths,
  pkgs,
  ...
}: let
  requiresData.unitConfig.RequiresMountsFor = [paths.media paths.apps];

  # LAN + tailnet only. Tailnet clients keep their 100.x source via the subnet
  # route, hence the 100.64/10 allow alongside the LAN range.
  private = port: {
    useACMEHost = "ramonr.ch";
    forceSSL = true;
    extraConfig = ''
      allow 192.168.1.0/24;
      allow 100.64.0.0/10;
      allow 127.0.0.1;
      deny all;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
in {
  users.groups.share.gid = 1111;
  users.groups.torrent.gid = 1020;
  users.users.torrent = {
    uid = 1020;
    group = "torrent";
    extraGroups = ["share"];
    isSystemUser = true;
  };

  # Port and auth are declarative; the rest (library paths, indexers, quality
  # profiles) lives in each app's SQLite DB. auth.method = External defers auth
  # to the network layer (nginx ACL + tailnet), so the apps run without a login.
  services.radarr = {
    enable = true;
    user = "torrent";
    group = "share";
    dataDir = paths.appDir "radarr";
    settings = {
      server.port = 7878;
      auth.method = "External";
    };
  };
  services.sonarr = {
    enable = true;
    user = "torrent";
    group = "share";
    dataDir = paths.appDir "sonarr";
    settings = {
      server.port = 8989;
      auth.method = "External";
    };
  };
  services.lidarr = {
    enable = true;
    user = "torrent";
    group = "share";
    dataDir = paths.appDir "lidarr";
    settings = {
      server.port = 8686;
      auth.method = "External";
    };
  };
  # Jackett's module has no `settings`; its base path and API key live in
  # ServerConfig.json under its dataDir, not in Nix.
  services.jackett = {
    enable = true;
    user = "torrent";
    group = "share";
    dataDir = paths.appDir "jackett";
  };

  systemd.services.radarr = requiresData;
  systemd.services.sonarr = requiresData;
  systemd.services.lidarr = requiresData;
  systemd.services.jackett = requiresData;

  # The module sandboxes transmission (chroot + BindPaths derived from settings),
  # so any path it must reach has to be declared here — a dir set only via the
  # web UI would be outside the sandbox and fail. Every RPC consumer is local
  # (nginx proxy + the *arrs), so the whitelist is 127.0.0.1.
  sops.secrets."transmission-rpc".owner = "torrent"; # JSON: {"rpc-password": "…"}
  services.transmission = {
    enable = true;
    user = "torrent";
    group = "share";
    home = paths.appDir "transmission";
    package = pkgs.transmission_4;
    credentialsFile = config.sops.secrets."transmission-rpc".path;
    settings = {
      download-dir = "${paths.downloads}/transmission";
      incomplete-dir-enabled = false;
      peer-port = 51413;
      rpc-authentication-required = true;
      rpc-username = "ramon";
      rpc-whitelist = "127.0.0.1";
      rpc-host-whitelist = "transmission.ramonr.ch";
      umask = "002"; # must be a string — an int is read as decimal, not octal
    };
    openPeerPorts = true;
  };
  systemd.services.transmission = requiresData;

  # Subdomains are by media type, not app name (easier to remember than which
  # *arr is which).
  services.nginx.virtualHosts = {
    "movies.ramonr.ch" = private 7878; # radarr
    "series.ramonr.ch" = private 8989; # sonarr
    "music.ramonr.ch" = private 8686; # lidarr
    "jackett.ramonr.ch" = private 9117;
    "transmission.ramonr.ch" = private 9091;
  };
}
