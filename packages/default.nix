{
  pkgs,
  unstable,
  ...
}: {
  home.packages = with pkgs; [
    _1password
    alejandra # nix formatter
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
    snyk
    terraform
    terraform-ls
    teleport
    tilt
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
