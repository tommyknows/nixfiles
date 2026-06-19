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
    bun
    coreutils
    ctlptl
    cmake
    circleci-cli
    diffutils
    delve
    deno
    # docker installed through docker desktop
    envsubst
    fd
    unstable.fish-lsp
    ffmpeg
    gh
    git-absorb
    gitleaks
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
    jujutsu
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
    nil # nix language server
    prettier
    markdownlint-cli
    unstable.nodejs_26
    #open-policy-agent
    postgresql
    pre-commit
    unstable.protobuf
    protoc-gen-go
    pstree
    python3
    qemu
    qrencode
    rancher
    unstable.rtk
    rustup
    sd
    shellcheck
    shfmt
    skopeo
    teleport
    terraform
    terraform-ls
    tilt
    translate-shell
    typescript-language-server
    universal-ctags
    vlc-bin
    wireguard-go
    wireguard-tools
    xz
    yarn
    yq
    unstable.zed-editor
    typescript
    cspell
  ];
}
