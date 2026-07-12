# Blocky: split-horizon override for *.ramonr.ch (so LAN/tailnet clients reach
# the server directly instead of hairpinning through the public IP) plus
# ad-blocking via AdGuard upstreams. Shared with the VM.
{...}: {
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      upstreams.groups.default = ["94.140.14.14" "94.140.14.15"]; # AdGuard DNS
      customDNS.mapping."ramonr.ch" = "192.168.1.1"; # covers all subdomains
      # filterUnmappedTypes defaults true → empty MX/TXT/CAA for the apex from the
      # LAN; set false if anything local ever needs those records.
    };
  };
  networking.firewall.allowedUDPPorts = [53];
  networking.firewall.allowedTCPPorts = [53];
}
