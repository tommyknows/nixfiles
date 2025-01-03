{...}: {
  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "My PRs";
          filters = "is:open author:@me";
          layout = {
            author = {hidden = true;};
          };
        }
        {
          title = "Needs Review";
          filters = "is:open review-requested:@me";
        }
        {
          title = "Involved";
          filters = "is:open -author:@me involves:@me";
        }
      ];
      defaults = {
        preview = {
          open = true;
          width = 100;
        };
        layout = {
          prs = {
            repo = {
              width = 20;
            };
          };
        };
      };
      pager = {
        diff = "delta";
      };
    };
  };
  programs.git = {
    enable = true;
    userName = "Ramon Rüttimann";
    userEmail = "me@ramonr.ch";
    signing = {
      key = null; # Enables GPG to auto-decide
      signByDefault = true;
    };
    ignores = [
      "node_modules"
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*" # thumbnails
      # vim related
      "[._]*.s[a-v][a-z]"
      "!*.svg"
      "[._]*.sw[a-p]"
      "[._]s[a-rt-v][a-z]"
      "[._]ss[a-gi-z]"
      "[._]sw[a-p]"
      "[._]*.un~" # persistent undo
    ];
    aliases = {
      br = "branch";
      c = "commit -S -v";
      ca = "commit -S --amend -v";
      cn = "commit -S --no-verify -v";
      cna = "commit -S --no-verify --amend -v";
      hash = "!git rev-parse HEAD | tr -d '\n'";
      msg = "log --format=\"%B\" -n 1";
      mrnotes = "!git log --reverse --format='%n%n**%s**%n%n%b' origin/HEAD..HEAD | pbcopy";
      plomr = "!fish -c \"git pull origin (default_branch) -r\"";
      pu = "push -u";
      puf = "push -u --force";
      put = "push --tags";
      pum = "push -u -o merge_request.create -o merge_request.remove_source_branch";
      st = "status";
      lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
      # git doesn't "find" the git-fix command, so let's alias it here.
      fix = "!fish -c \"git-fix\"";
      root = "rev-parse --show-toplevel";
      pick-commit = "!fish -c \"git-pick-commit\"";
    };
    attributes = [
      "go.sum binary"

      # `mergiraf languages --gitattributes` to generate list
      "*.java merge=mergiraf"
      "*.rs merge=mergiraf"
      "*.go merge=mergiraf"
      "*.js merge=mergiraf"
      "*.jsx merge=mergiraf"
      "*.json merge=mergiraf"
      "*.yml merge=mergiraf"
      "*.yaml merge=mergiraf"
      "*.html merge=mergiraf"
      "*.htm merge=mergiraf"
      "*.xhtml merge=mergiraf"
      "*.xml merge=mergiraf"
      "*.c merge=mergiraf"
      "*.cc merge=mergiraf"
      "*.h merge=mergiraf"
      "*.cpp merge=mergiraf"
      "*.hpp merge=mergiraf"
      "*.cs merge=mergiraf"
      "*.dart merge=mergiraf"
    ];
    extraConfig = {
      push = {default = "current";};
      pull = {rebase = true;};
      rebase = {updateRefs = true;};
      init = {defaultBranch = "main";};
      "branch \"master\"" = {
        remote = "origin";
        merge = "refs/heads/master";
      };
      "branch \"main\"" = {
        remote = "origin";
        merge = "refs/heads/main";
      };
      "remote.origin" = {
        prune = true;
      };
      "url \"ssh://git@github.com/\"" = {
        insteadOf = "https://github.com/";
      };
      "core" = {
        "hooksPath" = "/Users/ramon/.nixpkgs/programs/git/hooks";
      };
      merge = {
        name = "mergiraf";
        driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
      };
      absorb = {
        maxStack = 50;
        oneFixupPerCommit = true;
        autoStageIfNothingStaged = true;
      };
    };
    delta = {
      enable = true;
      options = {
        theme = "Monokai Extended Origin";
        features = "line-numbers decorations side-by-side";
      };
    };
  };
}
