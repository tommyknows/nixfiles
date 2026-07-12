# Disk health: smartd + Telegram notifications (host-only; real disks).
{
  config,
  pkgs,
  ...
}: let
  # The telegram-bot secret is an env file with two lines, so `.`-sourcing sets
  # both variables:
  #   TELEGRAM_BOT_TOKEN=...
  #   TELEGRAM_CHAT_ID=...
  # smartd passes the alert text in $SMARTD_MESSAGE. Test with
  # `smartctl -t short -M test <dev>`.
  telegramNotify = pkgs.writeShellScript "smartd-telegram" ''
    set -eu
    . ${config.sops.secrets."telegram-bot".path}
    ${pkgs.curl}/bin/curl -fsS \
      "https://api.telegram.org/bot''${TELEGRAM_BOT_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=''${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=[server smartd] ''${SMARTD_MESSAGE:-SMART alert}" \
      >/dev/null
  '';

  # smartd directive: monitor all attributes, enable automatic offline data
  # collection, run a short self-test nightly (03:xx) and a long self-test on
  # Saturday at the given hour, and route alerts to the Telegram notifier. The
  # long-test hour is staggered per disk so they don't all spin up at once.
  ataOpts = longHour: "-a -o on -s (S/../.././03|L/../../6/${longHour}) -m <nomailer> -M exec ${telegramNotify}";
in {
  sops.secrets."telegram-bot" = {}; # env file, read by the notifier (root)

  services.smartd = {
    enable = true;
    # by-id, not sdX — device letters shuffle across boots (and once the dead
    # SteamOS disk is pulled). Every disk the running system depends on is here:
    # tank's 4×8T + backup's 2×6T + the NVMe (NixOS root + ZFS SLOG/L2ARC).
    # Deliberately absent: the WD20EARX (dead SteamOS disk, pulled at cutover),
    # the Toshiba TR200 (untouched Ubuntu rollback disk), and the USB sticks.
    devices = [
      # tank — 2×mirror (4×8T)
      {
        device = "/dev/disk/by-id/ata-WDC_WD80EFAX-68KNBN0_VGGKV0LG";
        options = ataOpts "01";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD80EFAX-68LHPN0_7HJT4STF";
        options = ataOpts "02";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD80EFZX-68UW8N0_R6GWUPHY";
        options = ataOpts "03";
      }
      {
        device = "/dev/disk/by-id/ata-ST8000VN0022-2EL112_ZA1A35NR";
        options = ataOpts "04";
      }
      # backup — mirror (2×6T)
      {
        device = "/dev/disk/by-id/ata-WDC_WD60EFZX-68B3FN0_WD-CA128XJK";
        options = ataOpts "05";
      }
      {
        device = "/dev/disk/by-id/ata-WDC_WD60EFRX-68MYMN1_WD-WX41DA40LXTR";
        options = ataOpts "06";
      }
      # NVMe — NixOS root + ZFS SLOG/L2ARC. No `-o on` (automatic offline data
      # collection is ATA-only); a weekly long self-test still applies.
      {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNF0M748938A";
        options = "-a -s (L/../../6/07) -m <nomailer> -M exec ${telegramNotify}";
      }
    ];
    notifications.x11.enable = false;
    notifications.wall.enable = false;
  };
}
