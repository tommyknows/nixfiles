# Shared home-manager base — portable across the Macs and the NixOS server.
# Only things that make sense everywhere: shell, editor, VCS, core CLI tools.
# client.nix and server.nix both import this and layer their host-role extras.
{pkgs, ...}: {
  imports = [
    ./fish
    ./git
    ./jujutsu
    ./vim
    ./tmux
  ];

  # Portable CLI packages — safe on both macOS and Linux. Language toolchains,
  # cloud/k8s tooling, and GUI apps are client-only (see client.nix).
  home.packages = with pkgs; [
    # nix editing
    alejandra # formatter
    nil # language server
    # core CLI
    b3sum
    babelfish
    bat
    coreutils
    diffutils
    envsubst
    fd
    gh
    git-absorb
    gnupg
    hyperfine
    jless
    jq
    lz4
    mergiraf # AST-aware git merge driver
    pstree
    qrencode
    sd
    shellcheck
    shfmt
    tokei
    translate-shell
    universal-ctags
    xz
    yq
  ];

  programs = {
    lsd = {
      enable = true;
      settings.sorting.dir-grouping = "first";
    };
    fzf.enable = true;
    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        # --hidden descends into dotfiles/dirs, so re-exclude the VCS stores it
        # would otherwise search (.git and jj's .jj).
        "--glob"
        "  !.git"
        "--glob"
        "  !.jj"
      ];
    };
  };
}
