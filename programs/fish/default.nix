{
  pkgs,
  lib,
  hostname,
  ...
}: {
  xdg.configFile = {
    # load all completions and configs for fish from the Dotfiles repo.
    "fish/completions" = {
      source = ./completions;
      recursive = true;
    };
    "fish/conf.d" = {
      source = ./conf.d;
      recursive = true;
    };
    # adds the load-scripts to bobthefish's init files. Else they're not loaded for some reason.
    "fish/conf.d/plugin-bobthefish.fish".text = lib.mkAfter ''
      for f in $plugin_dir/*.fish
        source $f
      end
    '';

    "sfx" = {source = ../../sfx;};
  };

  # TODO: this is used as home-manager config, but maybe we can also set this as the toplevel
  # programs.fish config so that root gets the same shell?
  # Or do we just not care about root? ;)
  programs.fish = {
    enable = true;
    package = pkgs.unstable.fish;
    shellAliases = {
      # copycat - "cat-style" output for copying stuff.
      ccat = "bat --style snip";
      cat = "bat";
      cp = "cp -v";
      dps = ''docker ps --format "table {{printf \"%.25s\" .Names}}	{{.ID}}	{{.Image}}	{{.Command}}	{{.Ports}}	{{.Status}}"'';
      grb = "git pull origin (default_branch) --rebase";
      l = "lsd -l --group-dirs first";
      mv = "mv -v";
      rm = "rm";
      s = "sclone";
      vi = "vim";
    };
    shellAbbrs = {
      b = "bazel";
      d = "docker";
      g = "git";
      gtv = "go test -v .";
      gt = "go test ./...";
      "gt." = "go test .";
      gb = "go build ./...";
      "gb." = "go build .";
      gd = "go doc -all";
      gr = "git restore";
      grs = "git restore --staged";
      # three-dot syntax to compare against merge-base, not actual tip.
      # This makes it more similar to Github's diff view that will not
      # show updates to the main branch that aren't in the PR yet.
      gdm = "git diff origin/(default_branch)...";
      gds = "git diff --stat";
      groot = {
        position = "anywhere";
        function = "__groot";
        setCursor = true;
      };
      k = "kubectl";
      kctx = "kubectl ctx";
      rebuild = "sudo nix run nix-darwin -- switch --flake ~/Documents/nixfiles/main#${hostname}";
      tat = "tmux a -t";
      tan = "tmux new -s";
      tf = "terraform";
      untar = "tar -xvf";
    };
    # reads in all functions from :/fish/functions and registers them given their file name.
    functions =
      lib.mapAttrs'
      (
        name: _:
          lib.nameValuePair
          (builtins.head (builtins.split ".fish" name))
          {body = builtins.readFile (./. + ("/functions/" + name));}
      ) (lib.attrsets.filterAttrs (n: v: v == "regular") (builtins.readDir ./functions));
    plugins = [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "45a9ff6d0932b0e9835cbeb60b9794ba706eef10";
          sha256 = "pWkEhjbcxXduyKz1mAFo90IuQdX7R8bLCQgb0R+hXs4=";
        };
      }
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "6d8e962f3ed84e42583cec1ec4861d4f0e6c4eb3";
          sha256 = "0rnd8oJzLw8x/U7OLqoOMQpK81gRc7DTxZRSHxN9YlM=";
        };
      }
      {
        name = "bobthefish";
        src = pkgs.fetchFromGitHub {
          # custom fork to fine-tune git worktree handling.
          owner = "tommyknows";
          repo = "theme-bobthefish";
          sha256 = "miGpqrNub687ovCcN2qp3pzO+IDuwZ0stO88KMSt8t0=";
          rev = "9d5046821ca4d9641a0bab3f18f41ee16d8439ee";
        };
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        # TODO: doesn't really seem to work...at least autocompletion of container IDs doesn't work :(
        name = "docker-autocompletions";
        src = pkgs.fetchFromGitHub {
          owner = "halostatue";
          repo = "fish-docker";
          sha256 = "1B8Y7KtBVEcMojKPIapvK/sOIk99DqhXQuDXHRXzU7U=";
          rev = "086ce5f01bf1b9208c13b1a1e24cae1c099dda06";
        };
      }
    ];
    shellInit = builtins.readFile ./init.fish;
  };
}
