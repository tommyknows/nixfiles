# Client (macOS) home-manager profile: the shared base plus the Mac-only, dev,
# cloud, and GUI layers. Composed by the Mac hosts (hosts/<host>/home.nix).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./default.nix
    ./alacritty.nix
    ./autokbisw.nix
    ./claude
  ];

  # macOS-only packages: language toolchains, cloud/k8s tooling, GUI apps, and
  # secrets tooling. Portable CLI tools live in default.nix (shared).
  home.packages = with pkgs; [
    # secrets (sops editing; age-plugin-se = Secure-Enclave-backed age identity)
    sops
    age
    age-plugin-se
    # cloud / k8s / infra
    amazon-ecr-credential-helper
    awscli2
    aws-vault
    google-cloud-sdk
    google-cloud-sql-proxy
    kubectl
    kubectl-convert
    kubernetes-helm
    krew
    kustomize
    k9s
    kind
    ctlptl
    rancher
    tilt
    skopeo
    teleport
    circleci-cli
    ngrok
    terraform
    terraform-ls
    gitleaks
    wireguard-go
    wireguard-tools
    # languages / dev toolchains
    buf
    bun
    cmake
    delve
    deno
    unstable.fish-lsp
    unstable.golangci-lint
    unstable.gopls
    gotags
    gotestsum
    gotools
    graphviz
    unstable.helm-ls
    jekyll
    mockgen
    prettier
    markdownlint-cli
    cspell
    unstable.nodejs_26
    postgresql
    pre-commit
    unstable.protobuf
    protoc-gen-go
    python3
    qemu
    unstable.rtk
    rustup
    typescript
    typescript-language-server
    yarn
    unstable.zed-editor
    # GUI / mac
    # Ideally this would be in darwin/bluesnooze.nix...
    bluesnooze
    ffmpeg
    mpv
    vlc-bin
  ];

  # sops finds the editing identity here (macOS only). It's an age-plugin-se
  # handle to a Secure-Enclave key — device-bound and non-extractable — kept at
  # the repo root (above the jj worktrees, so it's worktree-independent and
  # untracked).
  home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/Documents/nixfiles/sops-age-identity.txt";

  programs = {
    go = {
      enable = true;
      env = {
        GOPATH = "${config.home.homeDirectory}/Documents/go";
        # Bug in Go: https://github.com/golang/go/issues/58218
        # TODO: might not be necessary anymore, especially with jj.
        GOFLAGS = "-buildvcs=false";
      };
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        ForwardAgent = false;
        IdentityAgent = "/Users/ramon/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      };
    };
  };
}
