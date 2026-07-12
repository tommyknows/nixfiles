# Interactive VM (aarch64) for local validation on the Mac:
#   nix run .#server-vm     (qemu + hvf; throwaway qcow2 in cwd)
#
# The service modules + throwaway adaptations are shared with the integration
# test in vm-common.nix; this file only adds what interactive use needs: a root
# disk, a bootloader, console autologin, and the qemu run config.
{
  lib,
  inputs,
  ...
}: {
  imports = [./vm-common.nix];

  # jackett fails to start in THIS VM only: the Linux closure realized on the
  # Mac's case-insensitive store collides bin/Jackett with bin/jackett and the
  # loader can't resolve it. The real x86_64 host and the Linux-built test are
  # unaffected. Left enabled so the VM matches the host.

  # Root disk for interactive boot. The qemu-vm module overrides "/" when
  # building the .vm, and the bootloader assertion needs satisfying for plain
  # toplevel eval; both are inert in the actual run.
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;

  # Console autologin as root for interactive poking.
  users.users.root.password = "";
  services.getty.autologinUser = "root";
  # To drive a headless checklist over the forwarded SSH port (2222), drop your
  # pubkey here:  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 …" ];

  virtualisation.vmVariant.virtualisation = {
    host.pkgs = inputs.nixos.legacyPackages.aarch64-darwin;
    graphics = false;
    memorySize = 4096;
    cores = 2;
    diskSize = 8192;
    forwardPorts = [
      {
        from = "host";
        host.port = 8096;
        guest.port = 8096;
      } # emby
      {
        from = "host";
        host.port = 8443;
        guest.port = 443;
      } # nginx
      {
        from = "host";
        host.port = 5353;
        guest.port = 53;
      } # blocky
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      } # ssh (checklist)
    ];
  };
}
