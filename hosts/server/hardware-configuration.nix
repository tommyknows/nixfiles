# PLACEHOLDER — replace with the real `nixos-generate-config` output at install.
#
# Exists only so the flake evaluates (and `nix flake check` passes) before the
# machine's real hardware scan exists. Every value is lib.mkDefault so the
# generated file overrides it cleanly.
{lib, ...}: {
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.initrd.availableKernelModules = lib.mkDefault ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };
}
