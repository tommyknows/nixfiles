{lib, ...}: {
  programs = {
    # TODO
    go.goPrivate = ["github.com/"];

    git.includes = [
      {
        condition = "gitdir:~/Documents/work/";
        contents = {
          user = {
            # TODO
            email = "";
            signingKey = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/e32ba26c8d9cc956faa4227ac641b3cf.pub";
          };
        };
      }
    ];

    fish = {
      # TODO
      shellInit = ''
        set -gx WORK_GITHUB_USER ""

        ## teleport doesn't like SSH agents like Secretive.
        ## https://github.com/gravitational/teleport/issues/22326
        #set -gx TELEPORT_ADD_KEYS_TO_AGENT no
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
