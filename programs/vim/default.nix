{pkgs, ...}:
# can these be moved to flake.nix / flake.lock?
let
  vim-material-monokai = pkgs.vimUtils.buildVimPlugin {
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
in {
  xdg.configFile.vim = {
    source = ./.;
    recursive = true;
  };
  programs.vim = {
    enable = true;
    settings = {
      background = "dark";
      copyindent = true;
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
      vim-dadbod-completion
      # manually installed since it's not in repos.
      #coc-buf-lint
      coc-git
      coc-go
      coc-jest
      coc-json
      coc-markdownlint
      coc-nvim
      coc-prettier
      coc-rust-analyzer
      coc-sh
      coc-snippets
      coc-tsserver
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
      vim-dadbod-ui
      vim-fish
      vim-fugitive
      vim-gh-line
      vim-gopher
      vim-markdown
      vim-markdown-toc
      vim-material-monokai
      vim-sandwich
      vim-terraform
      vim-test
      vim-tmux
      vim-tmux-clipboard
      vim-tmux-focus-events
      vim-tmux-navigator
      vim-vinegar
    ];
    extraConfig = builtins.readFile ./vimrc;
  };
}
