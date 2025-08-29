{lib, ...}: {
  programs = {
    go.goPrivate = ["github.com/snyk"];

    git.includes = [
      {
        condition = "gitdir:~/Documents/work/";
        contents = {
          user = {
            email = "ramon.ruttimann@snyk.io";
            signingKey = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/e32ba26c8d9cc956faa4227ac641b3cf.pub";
          };
        };
      }
    ];

    fish = {
      shellInit = ''
        set -gx WORK_GITHUB_USER "snyk"

        # Required for fnm (npm version manager...)
        # For some reason, shellInit is executed twice when run within tmux. We don't want that.
        if ! set -q FNM_ARCH
          fnm env --use-on-cd | source
        end

        # teleport doesn't like SSH agents like Secretive.
        # https://github.com/gravitational/teleport/issues/22326
        set -gx TELEPORT_ADD_KEYS_TO_AGENT no

        # and to install NPM packages
        set -gx NODE_PATH $HOME/.npm-packages/lib/node_modules
      '';

      functions =
        lib.mapAttrs'
        (
          name: _:
            lib.nameValuePair
            (builtins.head (builtins.split ".fish" name))
            (builtins.readFile (./. + ("/functions/" + name)))
        ) (lib.attrsets.filterAttrs (n: v: v == "regular") (builtins.readDir ./functions));
    };
  };
  #xdg.configFile."vim/coc-settings.json".text = ''
  #  {"languageserver": {
  #  //"snyk": {
  #  //  "command": "/Users/ramon/Documents/work/snyk-ls",
  #  //  "args": ["-l", "info", "-f", "/tmp/snyk-ls.log"],
  #  //  "filetypes": ["*"],
  #  //  "initializationOptions": {
  #  //    "sendErrorReports": "false",
  #  //    "insecure": "false",
  #  //    "manageBinariesAutomatically": "false",
  #  //    "cliPath": "/Users/ramon/Documents/work/snyk",
  #  //    "token": "3b414db8-03c5-46ca-a9e4-828f1e1d9cd8",
  #  //    "enableTelemetry": "false",
  #  //    "organization": "4e587e93-f7ea-46d4-a486-46f6dde32fac",
  #  //    "activateSnykCode": "true",
  #  //    "activateSnykIac": "false",
  #  //    "activateSnykOpenSource": "true",
  #  //    "integrationName": "vim",
  #  //    "integrationVersion": "0.10.0"
  #  //  }
  #  //}
  #  }}
  #'';
}
