# sops-nix base wiring. Individual secrets are declared next to the service that
# consumes them; this only points sops at the encrypted file and the key.
#
# The decryption key is derived from the host's SSH key. That key doesn't exist
# until the OS is installed, so secrets can't decrypt on the very first boot —
# either seed the host key before install, or accept one degraded boot and
# re-key afterwards.
{...}: {
  sops = {
    defaultSopsFile = ../../secrets/server.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
