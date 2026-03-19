{
  lib,
  pkgs,
  ic,
  ...
}: let
  ic-cli = pkgs.buildGoModule {
    pname = "ic";
    version = ic.shortRev or "dev";
    src = ic;
    subPackages = ["cmd/ic"];
    vendorHash = "sha256-baScParmfr1uNlyyrwUCaC2ssuTZm5tTyF8RuRbz8OY=";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/infracost/ic/internal/version.version=${ic.shortRev or "dev"}"
      "-X github.com/infracost/ic/internal/version.commit=${ic.rev or "dirty"}"
      "-X github.com/infracost/ic/internal/version.date=${ic.lastModifiedDate or "unknown"}"
      "-X github.com/infracost/ic/internal/version.builder=nix"
    ];
    flags = ["--trimpath"];
    env.CGO_ENABLED = "0";
  };
in {
  home.packages = [ic-cli];
  programs = {
    go.env.GOPRIVATE = "github.com/infracost";

    git.includes = [
      {
        condition = "gitdir:~/Documents/work/";
        contents = {
          user = {
            email = "ramon.ruttimann@infracost.io";
            signingKey = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/a1653ad1704845cd0eb35d5822dc9408.pub";
          };
        };
      }
    ];

    fish = {
      shellInit = ''
        set -gx WORK_GITHUB_USER "infracost"
      '';

      functions =
        lib.mapAttrs'
        (
          name: _:
            lib.nameValuePair
            (builtins.head (builtins.split ".fish" name))
            {body = builtins.readFile (./. + ("/functions/" + name));}
        ) (lib.attrsets.filterAttrs (n: v: v == "regular") (builtins.readDir ./functions));
    };
  };
}
