# nginx base + the single ACME DNS-01 wildcard cert (*.ramonr.ch via Cloudflare).
# Individual vhosts live next to their service (emby.nix, arrs.nix, opencloud.nix)
# and all reference useACMEHost = "ramonr.ch".
{config, ...}: {
  # Cloudflare API token for the ACME DNS-01 challenge, stored as an env file:
  #   CF_DNS_API_TOKEN=<token>
  # It must be a scoped token, restricted to the ramonr.ch zone, granting:
  #   Zone · DNS  · Edit  — write/remove the _acme-challenge TXT records
  #   Zone · Zone · Read  — resolve the zone id from the domain name
  # (Cloudflare's "Edit zone DNS" template omits Zone·Read, so build a custom
  # token.) Read by the acme service as root.
  sops.secrets."cloudflare-acme" = {};

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@ramonr.ch";
    certs."ramonr.ch" = {
      domain = "ramonr.ch";
      extraDomainNames = ["*.ramonr.ch"];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare-acme".path;
      group = "nginx";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
