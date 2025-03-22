{
  pkgs,
  unstable,
  ...
}: {
  home.packages = with pkgs; [
    alejandra # nix formatter
    awscli2
    aws-vault
    babelfish
    bat
    coreutils
    ctlptl
    cmake
    circleci-cli
    diffutils
    b3sum
    delve
    # docker installed through docker desktop
    fd
    fish-lsp
    fnm
    ffmpeg
    gh
    git-absorb
    gitleaks
    glab
    golangci-lint
    google-cloud-sdk
    google-cloud-sql-proxy
    gopls
    gotags
    gotestsum
    # things like present, godoc, goimports...
    gotools
    gnupg
    # harlequin # Good lookin' CLI SQL Editor, but not available in repos.
    hyperfine
    jekyll
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
    mergiraf # git merge driver that's AST-aware.
    mockgen
    neovim
    nodePackages_latest.markdownlint-cli
    nodePackages.prettier
    nodejs-slim
    open-policy-agent
    pam-reattach
    postgresql
    python310
    pre-commit
    protoc-gen-go
    protobuf
    pstree
    qemu
    qrencode
    rancher
    rustup
    sd
    shellcheck
    shfmt
    slack
    skopeo
    snyk
    terraform
    terraform-ls
    teleport
    tilt
    translate-shell
    universal-ctags
    velero
    wireguard-tools
    wireguard-go
    xz
    yq
    yarn
    nodePackages.ts-node
    nodePackages.typescript
    nodePackages.cspell
  ];
}
