{lib, ...}: {
  programs = {
    # TODO: next home-manager release moves this to go.env.GOPRIVATE.
    go.goPrivate = ["github.com/infracost"];

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
            (builtins.readFile (./. + ("/functions/" + name)))
        ) (lib.attrsets.filterAttrs (n: v: v == "regular") (builtins.readDir ./functions));
    };
  };
}
