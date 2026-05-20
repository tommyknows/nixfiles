{pkgs, ...}: let
  agent-safehouse = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "agent-safehouse";
    version = "0.10.0";

    src = pkgs.fetchurl {
      url = "https://github.com/eugene1g/agent-safehouse/releases/download/v${version}/safehouse.sh";
      hash = "sha256-mNDwh5XGUQeOXAOlGro7wqV2TMRDLa1VXJuEn4C1uMI=";
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 $src $out/bin/safehouse
    '';

    meta = {
      description = "Sandbox local AI agents on macOS via sandbox-exec";
      homepage = "https://agent-safehouse.dev";
      platforms = ["aarch64-darwin" "x86_64-darwin"];
    };
  };
in {
  home.packages = [agent-safehouse];

  # Machine-local appended profile sourced by `safe-claude` (and any other
  # safehouse invocation that passes --append-profile).
  xdg.configFile."agent-safehouse/local-overrides.sb".source = ./local-overrides.sb;

  programs.fish.functions.safe-claude = {
    description = "Run claude under agent-safehouse (--dangerously-skip-permissions)";
    body = ''
      safehouse \
          --add-dirs=$HOME/Documents/go:$HOME/Library/Caches/go-build \
          --add-dirs-ro=$HOME/Documents/work:$HOME/Documents/nixfiles \
          --append-profile=$HOME/.config/agent-safehouse/local-overrides.sb \
          -- claude --dangerously-skip-permissions $argv
    '';
  };
}
