# Admin authentication for the server. Two factors, both "something you have":
#   1. an SSH key — a Secure-Enclave key in Secretive (keys in system/nixos.nix)
#   2. a TOTP one-time code, required by sudo (below)
# ramon has NO password at all: the key logs you in, the OATH code authorises
# sudo. The only password anywhere is root's, and only for the physical console.
{
  config,
  lib,
  ...
}: {
  # Fully declarative users — no imperative `passwd`, no drift.
  users.mutableUsers = false;

  # Break-glass. root gets a password that works ONLY at the physical console /
  # serial: SSH has PasswordAuthentication off and won't accept root by password,
  # so this is not remotely usable. It's the recovery path if both Secure-Enclave
  # keys or the TOTP seed are lost — physical access is explicitly trusted (the
  # disk is unencrypted and GRUB is unlocked, so physical access is root anyway).
  # Generate the hash with `mkpasswd -m yescrypt` and store it under the
  # `root-password` key:  sops secrets/server.yaml
  sops.secrets."root-password".neededForUsers = true;
  users.users.root.hashedPasswordFile = config.sops.secrets."root-password".path;

  # sudo's second factor: a TOTP code (RFC 6238) via pam_oath, which NixOS
  # inserts as `requisite` — a missing or wrong code fails sudo immediately.
  # Since ramon has no unix password, pam_unix (which sits later as `sufficient`)
  # only succeeds if a null password is allowed; so we allow it FOR SUDO ONLY.
  # Net effect, because the requisite OATH runs first: correct TOTP ⇒ sudo.
  #
  # DANGER — these two settings are a matched pair. `allowNullPassword` WITHOUT
  # `oathAuth` is passwordless sudo with no authentication at all. Never set one
  # without the other. (SSH can't exploit the null password: password auth is off.)
  security.pam.oath = {
    enable = true;
    digits = 6;
    window = 3;
    # pam_oath rewrites this file (it records the last-used time step to stop
    # replay, even for TOTP), so it can't be the read-only sops secret. The seed
    # is copied here once from sops (below); rotate by editing sops + deleting
    # this file.
    usersFile = "/var/lib/oath/users.oath";
  };
  security.pam.services.sudo = {
    oathAuth = true;
    allowNullPassword = true;
  };

  # The TOTP seed lives in sops (source of truth); pam_oath needs a writable
  # copy. Seed it once, then leave pam_oath's replay-state bookkeeping alone.
  sops.secrets."oath" = {};
  systemd.tmpfiles.rules = ["d /var/lib/oath 0700 root root -"];
  system.activationScripts.oathSeed = {
    deps = ["setupSecrets"];
    text = ''
      if [ ! -e /var/lib/oath/users.oath ] && [ -e "${config.sops.secrets."oath".path}" ]; then
        install -Dm0600 -o root -g root "${config.sops.secrets."oath".path}" /var/lib/oath/users.oath
      fi
    '';
  };
}
