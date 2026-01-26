{pkgs, ...}: {
  # Currently, giving autokbisw the ability to monitor keyboard input is a
  # manual step. I don't think nix-darwin supports this yet.
  config.launchd.agents.autokbisw = {
    enable = true;
    config = {
      Program = "${pkgs.autokbisw}/bin/autokbisw";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/autokbisw.log";
      StandardErrorPath = "/tmp/autokbisw.log";
    };
  };
}
