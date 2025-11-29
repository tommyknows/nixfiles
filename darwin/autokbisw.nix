{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.unstable.autokbisw ];

  # Currently, giving autokbisw the ability to monitor keyboard input is a
  # manual step. I don't think nix-darwin supports this yet.
  launchd.user.agents.autokbisw = {
    command = "${pkgs.unstable.autokbisw}/bin/autokbisw";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/autokbisw.log";
      StandardErrorPath = "/tmp/autokbisw.log";
    };
  };
}
