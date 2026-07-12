# Private Mac — per-host system config (composes system/darwin via the flake).
{...}: {
  system.defaults.dock.persistent-apps = ["/Applications/Logic Pro.app"];
}
