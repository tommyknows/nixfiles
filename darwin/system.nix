{
  pkgs,
  config,
  ...
}: {
  fonts.packages = [(pkgs.nerdfonts.override {fonts = ["SourceCodePro"];})];
  system = {
    stateVersion = 4;
    defaults = {
      dock.autohide = true;
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

    # make applications show up in spotlight...
    activationScripts.applications.text = pkgs.lib.mkForce ''
      echo "setting up ~/Applications/..."
      rm -rf ~/Applications/*
      find ${config.system.build.applications}/Applications -maxdepth 1 -type l | while read -r f; do
        src="$(/usr/bin/stat -f%Y "$f")"
        appname="$(basename "$src")"
        osascript -e "tell app \"Finder\" to make alias file at POSIX file \"/Users/ramon/Applications/\" to POSIX file \"$src\" with properties {name: \"$appname\"}";
      done
      mkdir -p /usr/local/bin
    '';
  };

  security = {
    # https://github.com/LnL7/nix-darwin/pull/228
    pam.enableSudoTouchIdAuth = true;
  };

  # never not going to have an ARM Mac
  nixpkgs.hostPlatform = "aarch64-darwin";
}
