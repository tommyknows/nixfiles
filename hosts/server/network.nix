# Static LAN identity + Tailscale (host-only; the VM uses QEMU user-networking
# and doesn't import this). Blocky lives in dns.nix (shared).
{config, ...}: {
  # Rename the LAN NIC by its permanent MAC so sdX-style churn (pulling sdb,
  # swapping the OS disk) can't reshuffle it. MAC is the box's eth1; eth0 unused.
  systemd.network.links."10-lan" = {
    matchConfig.PermanentMACAddress = "0c:9d:92:c5:d9:c6";
    linkConfig.Name = "lan0";
  };

  networking = {
    useDHCP = false;
    interfaces.lan0.ipv4.addresses = [
      {
        address = "192.168.1.1";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.254";
    nameservers = ["127.0.0.1"]; # resolve *.ramonr.ch locally via blocky
  };

  sops.secrets."tailscale-authkey" = {}; # optional; else `tailscale up` once
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server"; # sets forwarding sysctls
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    extraSetFlags = [
      "--advertise-exit-node"
      "--advertise-routes=192.168.1.0/24"
    ];
  };
}
