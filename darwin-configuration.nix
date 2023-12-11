{ config, pkgs, lib, ... }:

let
  vim-material-monokai  = pkgs.vimUtils.buildVimPlugin {
    name = "material-monokai";
    src = pkgs.fetchFromGitHub {
        owner = "tommyknows";
        repo = "vim-material-monokai";
        rev = "267d0a30faa62db893ef36d5c94213264cd48f93";
        sha256 = "B01qZkzHUg3gn8mlXS63tSKP+9Nqd9wpJBFFkII3jk4=";
    };
  };
  vim-gopher = pkgs.vimUtils.buildVimPlugin {
    name = "gopher.vim";
    src = pkgs.fetchFromGitHub {
      owner = "arp242";
      repo = "gopher.vim";
      rev = "63bb911d44fe3886ef2fe13668f3e8258cfaea2e";
      sha256 = "WNU6ZZT9a5tyKcqLYvcXi7v39xdYoS84C+93UqEub9Q=";
    };
  };
  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/nixos-unstable)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in {
  imports = [ <home-manager/nix-darwin> ];
  # allow closed source packages as well.
  nixpkgs.config.allowUnfree = true;

  system = {
    stateVersion = 4;
    defaults = {
      dock.autohide = true;
      NSGlobalDomain = {
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        _HIHideMenuBar = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
        #FirstClickThreshold = 0;
        #SecondClickThreshold = 0;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # make applications show up in spotlight...
    activationScripts.applications.text = pkgs.lib.mkForce (''
        echo "setting up ~/Applications/..."
        rm -rf ~/Applications/*
        find ${config.system.build.applications}/Applications -maxdepth 1 -type l | while read f; do
          src="$(/usr/bin/stat -f%Y $f)"
          appname="$(basename $src)"
          osascript -e "tell app \"Finder\" to make alias file at POSIX file \"/Users/ramon/Applications/\" to POSIX file \"$src\" with properties {name: \"$appname\"}";
        done
        mkdir -p /usr/local/bin
    '');
  };


  users.users.ramon = {
    name = "ramon";
    home = "/Users/ramon";
    shell = pkgs.fish;
  };
  security = {
    # https://github.com/LnL7/nix-darwin/pull/228
    pam.enableSudoTouchIdAuth = true;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users.ramon = {
    xdg.configFile = {
      # load all completions and configs for fish from the Dotfiles repo.
      "fish/completions" = { source = ./fish/completions; recursive = true; };
      "fish/conf.d" = { source = ./fish/conf.d; recursive = true; };
      # adds the load-scripts to bobthefish's init files. Else they're not loaded for some reason.
      "fish/conf.d/plugin-bobthefish.fish".text = lib.mkAfter ''
        for f in $plugin_dir/*.fish
          source $f
        end
        '';
      "vim" = { source = ./vim; recursive = true; };
    };
    home = {
      packages = with pkgs; [
        _1password
        awscli2
        aws-vault
        babelfish
        bat
        bazel_6
        bazelisk
        coreutils
        ctlptl
        cmake
        circleci-cli
        diffutils
        b3sum
        delve
        deno
        # docker installed through docker desktop
        fd
        fnm
        ffmpeg
        fzf
        gitleaks
        glab
        unstable.golangci-lint
        google-cloud-sdk
        google-cloud-sql-proxy
        unstable.gopls
        gotags
        gotestsum
        # things like present, godoc, goimports...
        gotools
        gnupg
        iterm2
        jless
        jq
        kind
        # Kubebuilder needs additional tools (etcd, apiserver) which are currently not
        # bundled with that package. See https://github.com/NixOS/nixpkgs/issues/205741
        #kubebuilder
        kubectl
        kubectl-convert
        kubernetes-helm
        krew
        kustomize
        loc
        lz4
        mockgen
        neovim
        nodePackages_latest.markdownlint-cli
        nodePackages.prettier
        nodejs 
        open-policy-agent
        pam-reattach
        postgresql
        python310
        pre-commit
        protoc-gen-go
        protobuf3_20
        qemu
        qrencode
        rancher
        ripgrep
        rustup
        sd
        shellcheck
        shfmt
        slack
        skopeo
        terraform
        terraform-ls
        unstable.teleport_13
        tilt
        universal-ctags
        velero
        wireguard-tools
        xz
        yq
        yarn
        # TODO: doesn't build.
        # unstable.snyk
        unstable.helix
        nodePackages.ts-node
        nodePackages.typescript
        nodePackages.cspell
      ];
    stateVersion = "22.11";
    };
    programs = {
      vim = {
        enable = true;
        settings = {
          background = "dark";
          copyindent = true;
          expandtab = true;
          hidden = true;
          history = 1000;
          ignorecase = true;
          mouse = "a";
          number = true;
          shiftwidth = 4;
          smartcase = true;
          tabstop = 4;
          undodir = ["/tmp/vim-undo"];
        };
        plugins = with pkgs.vimPlugins; [
          auto-pairs
          camelcasemotion
          coc-diagnostic
          coc-git
          coc-json
          coc-markdownlint
          unstable.vimPlugins.coc-nvim
          coc-prettier
          coc-python
          coc-jest
          coc-rust-analyzer
          coc-snippets
          coc-tslint-plugin
          coc-yaml
          fzf-vim
          indentLine
          markdown-preview-nvim
          nerdcommenter
          rust-vim
          tagbar
          vimspector
          vim-airline
          vim-airline-themes
          vim-bufkill
          vim-cue
          vim-fish
          vim-fugitive
          vim-gh-line
          vim-gopher
          vim-markdown
          vim-material-monokai
          vim-surround
          vim-terraform
          vim-tmux
          vim-tmux-clipboard
          vim-tmux-focus-events
          vim-tmux-navigator
          vim-vinegar
        ];
        extraConfig = (builtins.readFile ./vim/vimrc);
      };
      git = {
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
        ];
        extraConfig = {
          push = { default = "current"; };
          pull = { rebase = true; };
          init = { defaultBranch = "main"; };
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
            # TODO: This is needed to fetch the origin's branches and update them locally.
            # Sadly it breaks submodules with the weird "multiple updates to ref" error
            # message that I have no idea how to fix.
            fetch = "+refs/heads/*:refs/remotes/origin/*";
          };
          "url \"ssh://git@github.com/\"" = {
            insteadOf = "https://github.com/";
          };
          "core" = {
            "hooksPath" = "/Users/ramon/.nixpkgs/git-hooks";
          };
        };
        includes = [{
            condition = "gitdir:~/Documents/work/";
            contents = {
              user = { email = "ramon.ruttimann@snyk.io"; };
            };
        }];
        delta = {
          enable = true;
          options = {
            theme = "Monokai Extended Origin";
            features = "line-numbers decorations side-by-side";
          };
        };
      };
      fish = {
        enable = true;
        package = unstable.fish;
        shellAliases = {
          # copycat - "cat-style" output for copying stuff.
          ccat = "bat --style snip";
          cat = "bat";
          cp = "cp -v";
          dps = "docker ps --format \"table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Ports}}\t{{.Status}}\"";
          grb = "git pull origin (default_branch) --rebase";
          l = "lsd -l --group-dirs first";
          la = "lsd -a";
          lla = "lsd -la";
          ls = "lsd";
          lt = "lsd --tree";
          mv = "mv -v";
          rm = "rm";
          s = "sclone";
          vi = "vim";
        };
        shellAbbrs = {
          b = "bazel";
          g = "git";
          gtv = "go test -v .";
          gt = "go test ./...";
          "gt." = "go test .";
          gb = "go build ./...";
          "gb." = "go build .";
          gdm = "git diff (default_branch)";
          gds = "git diff --stat";
          k = "kubectl";
          kctx = "kubectl ctx";
          tat = "tmux a -t";
          tan = "tmux new -s";
          untar = "tar -xvf";
        };
        # reads in all functions from :/fish/functions and registers them given their file name.
        functions = lib.mapAttrs'
          (name: _: lib.nameValuePair
            (builtins.head (builtins.split ".fish" name))
            (builtins.readFile (./. + ("/fish/functions/"+name)))
          ) (lib.attrsets.filterAttrs (n: v: v == "regular") (builtins.readDir ./fish/functions));
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
        shellInit = builtins.readFile ./fish/init.fish;
      };
      go = {
        enable = true;
        package = unstable.go_1_21;
        goPath = "Documents/go";
        goPrivate = ["github.com/snyk"];
      };
      lsd = {
        enable = true;
        settings = {
          sorting = { dir-grouping = "first"; };
        };
      };
      ssh = {
        enable = true;
        extraConfig = "IdentityAgent /Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      };
      tmux = {
        enable = true;
        clock24 = true;
        keyMode = "vi";
        terminal = "xterm-256color-italic";
        shell = "${unstable.fish}/bin/fish";
        sensibleOnTop = true;
        escapeTime = 1;
        baseIndex = 1;
        extraConfig = builtins.readFile ./tmux/config.tmux;
        plugins = with pkgs.tmuxPlugins; [
          tmux-thumbs
          vim-tmux-navigator
          {
            plugin = battery;
            extraConfig = ''
set -g status-left "#[fg=#ffffff,bg=#506E79,bold] #S #[fg=#506E79,bg=#1f292d]"
setw -g window-status-format "#[fg=#b0bec5,bg=#1f292d] #I #W "
#setw -g window-status-current-format "#[fg=colour67,bg=colour16,nobold,nounderscore,noitalics]#[fg=colour253,bg=colour16] #I #[fg=colour253,bg=colour16] #W #[fg=colour16,bg=colour67,nobold,nounderscore,noitalics]"
setw -g window-status-current-format "#[fg=#1f292d,bg=#b0bec5]#[fg=#1f292d,bg=#b0bec5,nobold,nounderscore,noitalics] #I #W #[fg=#b0bec5,bg=#1f292d]"

# indicate whether Prefix has been captured + time in the right-status area
set -g status-right "#[fg=#b0bec5,bg=#1f292d]#[fg=#1f292d,bg=#b0bec5] #{battery_icon} #{battery_percentage} | #{cpu_percentage} #[fg=#506E79,bg=#b0bec5]#[fg=#ffffff,bg=#506E79] %H:%M #[fg=#fd9720,bg=#506E79]#[fg=#1f292d,bg=#fd9720] %h %d #[fg=#e73c50,bg=#fd9720]#[fg=#ffffff,bold,bg=#e73c50]#{?client_prefix, TRIGGERED ,}"
## Status bar that shows networking infos too
'';
          }
          cpu
          yank
          {
            plugin = resurrect;
            extraConfig = "
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-capture-pane-contents 'on'
";
          }
        ];
      };
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.settings = {
    sandbox = true;
  };

  programs.zsh.enable = false;
  programs.fish = {
    enable = true;
    useBabelfish = true;
    babelfishPackage = "${pkgs.babelfish}";
  };

  environment.loginShell = "${pkgs.fish}/bin/fish";

  nix.configureBuildUsers = true;
  nix.nrBuildUsers = 32;
}
