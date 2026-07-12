# Zero-patch repack of the upstream Emby .deb.
#
# The Emby deb is designed to be distro-independent: it bundles its own glibc,
# ffmpeg, SkiaSharp, SQLite, and its ELF binaries use a *relative* interpreter
# path (lib/ld-linux-*.so.2), so they run on NixOS unpatched. This is a repack,
# NOT a build — hence dontStrip/dontPatchELF and substituteInPlace restricted to
# the shell launchers only (running string replacement over the ELF binaries in
# bin/ would corrupt them).
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
}: let
  version = "4.9.5.0";

  # Arch-conditional: the amd64 deb for the real x86_64 server, the arm64 deb for
  # the aarch64 VM variant. Hashes prefetched with `nix store prefetch-file`.
  debs = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-HXGP+gFpw5PePq/aZbGwV6PbTq2T/+tYg6vQFzXemEM=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-swGIhNhdywn2vw0p8Slq8nfF4smbU1m4HToemocgRbc=";
    };
  };

  deb =
    debs.${stdenv.hostPlatform.system}
    or (throw "emby-server: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "emby-server";
    inherit version;

    src = fetchurl {
      url = "https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-deb_${version}_${deb.arch}.deb";
      inherit (deb) hash;
    };

    nativeBuildInputs = [dpkg];

    # The bundled loader/glibc must stay intact — do NOT let the generic fixup
    # phases touch the ELF binaries.
    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;

    # Extract into a fresh subdirectory rather than `.`: dpkg-deb's tar restores
    # mode/mtime on the extraction root, which fails when the build root forbids
    # metadata changes (the Determinate native Linux builder's build dir is such
    # a mount — `tar: .: Cannot utime: Operation not permitted`). A subdirectory
    # that tar creates itself has no such restriction.
    unpackPhase = ''
      dpkg-deb -x $src emby-deb
      cd emby-deb
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r opt/emby-server/* $out/
      # The deb ships a systemd unit for Debian's layout; we provide our own.
      rm -rf $out/lib/systemd

      # ONLY the shell launchers get their hard-coded /opt/emby-server prefix
      # rewritten to the store path. --replace-quiet: don't fail if a future deb
      # drops one of these references.
      substituteInPlace $out/bin/emby-server $out/bin/emby-ffmpeg \
        --replace-quiet /opt/emby-server $out

      runHook postInstall
    '';

    # dpkg-deb already produced final binaries; no reason to re-run fixup that
    # could rewrite the bundled interpreter.
    dontFixup = true;

    meta = {
      description = "Emby media server (repacked upstream .deb, unpatched)";
      homepage = "https://emby.media";
      license = lib.licenses.unfree;
      platforms = builtins.attrNames debs;
      mainProgram = "emby-server";
    };
  }
