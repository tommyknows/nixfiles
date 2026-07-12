# Homeserver (real x86_64 target). Aggregates the per-service modules; each owns
# its service + vhost + firewall + secret. Shared base is in base.nix (also used
# by the VM variant); host-only modules (zfs, network, monitoring) are added here
# and left out of vm.nix.
{...}: {
  imports = [
    ./hardware-configuration.nix # placeholder — replaced by the real scan at install
    ./base.nix
    ./sops.nix
    ./auth.nix # admin login: SSH key + TOTP-for-sudo, root console break-glass
    ./zfs.nix
    ./nginx.nix
    ./arrs.nix
    ./emby.nix
    ./opencloud.nix
    ./samba.nix
    ./dns.nix
    ./network.nix
    ./monitoring.nix
  ];
}
