{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra # nix formatter
    amazon-ecr-credential-helper
    awscli2
    aws-vault
    b3sum
    babelfish
    bat
    # Ideally this would be in darwin/bluesnooze.nix...
    bluesnooze
    buf
    coreutils
    ctlptl
    cmake
    circleci-cli
    unstable.crush
    diffutils
    delve
    # docker installed through docker desktop
    fd
    unstable.fish-lsp
    ffmpeg
    gh
    git-absorb
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
    graphviz
    # harlequin # Good lookin' CLI SQL Editor, but not available in repos.
    unstable.helm-ls
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
    k9s
    tokei
    lz4
    mergiraf # git merge driver that's AST-aware.
    mockgen
    mpv
    ngrok
    nodePackages.prettier
    nodePackages_latest.markdownlint-cli
    nodejs_22
    #open-policy-agent
    postgresql
    pre-commit
    unstable.protobuf
    protoc-gen-go
    pstree
    python310
    qemu
    qrencode
    rancher
    rustup
    sd
    shellcheck
    shfmt
    slack
    skopeo
    teleport
    terraform
    terraform-ls
    tilt
    translate-shell
    universal-ctags
    vlc-bin
    wireguard-go
    wireguard-tools
    xz
    yarn
    yq
    zed-editor
    nodePackages.typescript
    nodePackages.cspell
  ];
}
