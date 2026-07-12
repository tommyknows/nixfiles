{
  config,
  lib,
  pkgs,
  ic,
  infracost_cli,
  cloud-data,
  ...
}: let
  cloudDataReplaceModule = "github.com/infracost/cloud-data/api/gen/go@v0.0.29";
  ic-cli = (pkgs.buildGoModule.override {go = pkgs.go_1_26;}) {
    pname = "ic";
    version = ic.shortRev or "dev";
    src = ic;
    subPackages = ["cmd/ic"];
    vendorHash = "sha256-3zVh5BiEKtfV2+qYqH3NFkU3E/BcsN1gSmNLBquJ6jY=";
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
    postConfigure = ''
      go mod edit -replace ${cloudDataReplaceModule}=./cloud-data-local
    '';
    overrideModAttrs = _: {
      postConfigure = ''
        cp -r ${cloud-data}/api/gen/go cloud-data-local
        go mod edit -replace ${cloudDataReplaceModule}=./cloud-data-local
      '';
    };
  };
  infracost-cli = pkgs.buildGoModule {
    pname = "infracost";
    version = ic.shortRev or "dev";
    src = infracost_cli;
    subPackages = ["."];
    vendorHash = "sha256-Gm+B37QpscV9Qopan/TEedrLcNVz3p/rVst9aEe0/b0=";
    ldflags = [
      "-s"
      "-w"
      # default to 2.0.0 because the infracost skills require at least 2.0.0.
      "-X github.com/infracost/cli/version.Version=2.0.0"
    ];
    flags = ["--trimpath"];
    env.CGO_ENABLED = "0";
    nativeCheckInputs = [pkgs.git];
    postInstall = ''
      mv $out/bin/cli $out/bin/infracost
    '';
  };
in {
  imports = [./claude.nix];

  home.packages = [ic-cli infracost-cli pkgs.grpcurl];
  programs = {
    go.env.GOPRIVATE = "github.com/infracost/*";

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

    # jj equivalent of the git includeIf above: work identity + signing key
    # for any repo under ~/Documents/work.
    jujutsu.settings."--scope" = [
      {
        "--when".repositories = ["${config.home.homeDirectory}/Documents/work"];
        user.email = "ramon.ruttimann@infracost.io";
        signing.key = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/a1653ad1704845cd0eb35d5822dc9408.pub";
      }
    ];

    fish = {
      shellInit = ''
        set -gx WORK_GITHUB_USER "infracost"
        set -gx CODE_DIR "$HOME/Documents/work"
      '';

      functions =
        lib.mapAttrs'
        (
          name: _:
            lib.nameValuePair
            (builtins.head (builtins.split ".fish" name))
            {body = builtins.readFile (./. + ("/functions/" + name));}
        ) (lib.attrsets.filterAttrs (_n: v: v == "regular") (builtins.readDir ./functions));
    };
  };
}
