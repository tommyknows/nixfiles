{...}: {
  # disable nix as it's installed and managed through determinate.
  nix.enable = false;

  system.defaults.dock.persistent-apps = ["/Applications/Logic Pro.app"];
}
