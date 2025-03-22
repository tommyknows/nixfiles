{
  pkgs,
  config,
  ...
}: {
  fonts.packages = [(pkgs.nerdfonts.override {fonts = ["SourceCodePro"];})];
  system = {
    stateVersion = 4;
    defaults = {
      dock = {
        autohide = true;

        persistent-apps = let
          hmApps = ["Alacritty"];
        in
          [
            "/Applications/Safari.app"
            "/System/Applications/Mail.app"
            "/System/Applications/Maps.app"
            "/System/Applications/Calendar.app"
            "/Applications/Signal.app"
            "/Applications/WhatsApp.app"
            "/Applications/Emby.app"
          ]
          ++ map (hmApp: "/Users/ramon/Applications/Home Manager Apps/${hmApp}.app") hmApps;
      };

      finder.FXPreferredViewStyle = "Nlsv"; # list view

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      NSGlobalDomain = {
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        _HIHideMenuBar = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  security = {
    # https://github.com/LnL7/nix-darwin/pull/228
    # replace with below for 24.11 -> 25.05 upgrade.
    # should also be possible to remove the pam_reattach package.
    pam.enableSudoTouchIdAuth = true;
    #pam.services.sudo_local = {
    #  touchIdAuth = true;
    #  reattach = true;
    #};
  };

  # never not going to have an ARM Mac
  nixpkgs.hostPlatform = "aarch64-darwin";
}
