{
  pkgs,
  config,
  ...
}: {
  fonts.packages = [
    pkgs.nerd-fonts.sauce-code-pro
  ];
  system = {
    stateVersion = 4;
    defaults = {
      dock = {
        autohide = true;
        # do not rearrange spaces based on most-recent use.
        mru-spaces = false;

        persistent-apps = let
          hmApps = ["Alacritty"];
        in
          [
            "/Applications/Safari.app"
            "/System/Applications/Mail.app"
            "/System/Applications/Maps.app"
            "/System/Applications/Calendar.app"
            "/Applications/Signal.app"
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
        # Move Windows by Ctrl+Cmd-dragging them.
        NSWindowShouldDragOnGesture = true;
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
      CustomUserPreferences = {
        # Disable personalized ads
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
      };

      # Show battery percentage in the menu bar
      controlcenter.BatteryShowPercentage = true;
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  security = {
    pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };
  };
}
