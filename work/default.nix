{lib, ...}: {
  programs = {
    go.goPrivate = ["github.com/snyk"];

    git.includes = [
      {
        condition = "gitdir:~/Documents/work/";
        contents = {
          user = {email = "ramon.ruttimann@snyk.io";};
        };
      }
    ];

    fish = {
      shellInit = ''
        set -gx WORK_GITHUB_USER "snyk"

        # Required for fnm (npm version manager...)
        # For some reason, this adds the fnm_multishells path to the PATH variable TWICE:
        # once as one of the last entries in PATH, and one where I would expect it given the load order...
        fnm env --use-on-cd | source

        set -gx SNYK_API_TOKEN (security find-generic-password -a "ramon.ruttimann@snyk.io" -s "Snyk API Token" -w)

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
}
