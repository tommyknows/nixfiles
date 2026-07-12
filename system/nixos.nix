# Shared NixOS system layer — the counterpart to system/darwin. Generic base for
# any NixOS host here (currently just the server). Host identity and services
# live under hosts/<host>/.
{pkgs, ...}: {
  imports = [./nixpkgs.nix]; # shared nixpkgs.config (unfree allowance)

  # Admin user. Deploys land over SSH as ramon with `--sudo --ask-sudo-password`.
  users.users.ramon = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel"];
    shell = pkgs.fish;
    # Login keys (password auth is disabled below). Two dedicated Secure-Enclave
    # keys held in Secretive, one per Mac — private keys are non-extractable and
    # every use needs Touch ID. Two devices on purpose: losing one Mac doesn't
    # lock you out, and neither does a GitHub compromise (nothing is fetched).
    # Recovery if both are lost is the root console (see users.users.root).
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ9tU0yoVO8Wr7aoLtJmi2GXXG9XKtRVn81aOOpnMmm6CLArBYontvvvK55ISA2CLZ25vpOcQsLGW9wCkPItJ2k= Server@secretive.Ramon’s-MacBook-Pro.local"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIKGCAi+y2qZOsTcxnMz6Ut/uh/r1XRxGBLDMpDtMeH5fcmr0TxhDNI9yxvwliStMojcOvfLIaFCnPC30441YP8= Server@secretive.Ramon’s-MacBook-Air.local"
    ];
  };
  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
