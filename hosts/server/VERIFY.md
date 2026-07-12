# Pre-migration verification

Checks that can't run on the Mac, plus the secrets timeline. Everything here is
safe to run against the live Ubuntu box: it only adds `/nix` and *builds* (and,
for the integration test, boots throwaway isolated VMs) — no activation, no ZFS,
no k8s, no host ports touched.

**Why not the Mac?** The Determinate native Linux builder shares the Mac's
*case-insensitive* APFS Nix store into the Linux builder VM. Store paths with
case-colliding filenames are stored with `~nix~case~hack~N` suffixes, and the
case-sensitive Linux build then can't find them — so building a full NixOS
toplevel (either arch) dies in `make-initrd-ng` reading ncurses' terminfo
(`l/linux` → ENOENT). Leaf packages build fine; full systems don't. A real Linux
store (the Ubuntu box, or the server itself) is case-sensitive and unaffected.

## 1. Build the real x86_64 closure (on the Ubuntu box)

Because of the case-hack above, the full `x86_64-linux` closure can't be built
on the Mac at all — the initrd fails. Building it here catches x86_64-only
breakage (mainly that the amd64 Emby repack assembles) and is the first end-to-end
build of the whole system.

```bash
# a. Install Determinate Nix (flakes on by default)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

```fish
# b. Copy the worktree over from the Mac (skip .jj + big images). Not yet
#    committed, so copy rather than clone:
rsync -a --exclude .jj --exclude '*.png' --exclude '*.html' \
  ~/Documents/nixfiles/server/ <user>@server:~/nixfiles-server/
```

```bash
# c. On the Ubuntu box — build the toplevel (no switch, no activate).
#    `path:` copies the tree in, so no git-tracking needed.
nix build -L \
  'path:/home/<user>/nixfiles-server#nixosConfigurations.server.config.system.build.toplevel'
```

Green = the whole x86_64 system builds, incl. the amd64 Emby repack. Only public
inputs are fetched (`nixos-26.05`, `sops-nix`, `home-manager`); the infracost
`git+ssh` inputs aren't in the server's dependency path, so no GitHub SSH is
needed. `flake.lock` travels with the copy, so revisions are pinned. Emby's
unfree allowance is handled inside the config — no `NIXPKGS_ALLOW_UNFREE`.
If the Emby hash ever mismatches, fix the `x86_64-linux` hash in
`packages/emby-server/default.nix`.

Optional x86_64 boot smoke-test on the same box (this is also blocked on the Mac
by the case-hack — the VM is a full toplevel):

```bash
nix build -L 'path:/home/<user>/nixfiles-server#nixosConfigurations.server.config.system.build.vm' \
  && ./result/bin/run-*-vm   # throwaway; Ctrl-a x to quit
```

## 2. Run the automated integration test (on the Ubuntu box)

The `server-services` NixOS test (services up, split-horizon DNS, nginx ACL
allow *and* deny, transmission RPC auth, samba shares, jackett-on-Linux) needs a
builder with the `nixos-test` feature and real KVM — the Ubuntu box has both.
(On the Mac it's authored and passes type-check + lint but can't execute: the
VM-based builder lacks `nixos-test` and nested KVM needs an M3+ host.)

```bash
nix build -L 'path:/home/<user>/nixfiles-server#checks.x86_64-linux.server-services'
```

Boots two throwaway VMs and runs `hosts/server/test-script.py`; green = every
assertion passed. Coverage: services up, split-horizon DNS, nginx ACL allow *and*
deny, transmission RPC auth, samba shares, jackett-on-Linux, and **sudo requires a
valid TOTP** (auth.nix's OATH policy — this is its first real execution; it can't
run on the Mac).

**Safe on the live box.** The VMs are fully isolated QEMU guests: their
transmission/emby/etc. bind inside the guest's own virtual network (the test's
private VLANs, not the host LAN), disks are throwaway tmpfs, and no host port or
ZFS pool is touched. They cannot clash with the server's running instances. Cost
is only CPU/RAM/disk while they run, and `/dev/kvm` access (be in the `kvm` group).

To poke interactively (e.g. try the sudo/OTP prompt by hand, inspect logs):

```bash
nix build -L 'path:/home/<user>/nixfiles-server#checks.x86_64-linux.server-services.driverInteractive'
./result/bin/nixos-test-driver     # Python REPL: start_all(); server.shell_interact(); …
```

## 3. sops editing key — verified working (on the Mac)

Confirmed 2026-07-13: the Secure-Enclave age identity + `.sops.yaml` decrypt the
secrets file end to end (Touch ID). Ad-hoc, no rebuild needed:

```fish
env SOPS_AGE_KEY_FILE="$HOME/Documents/nixfiles/sops-age-identity.txt" \
  nix shell nixpkgs#sops nixpkgs#age-plugin-se --command \
  sops -d "$HOME/Documents/nixfiles/server/secrets/server.yaml"
```

Editing (fill real values) is the same command without `-d`, plus `EDITOR=vim`.

## 4. Secrets: fill them AT cutover, not before

`secrets/server.yaml` holds `CHANGE_ME_…` placeholders on purpose. Fill real
values during cutover, because:

- The server can only decrypt once its own host-key age recipient is added
  (step b below) — that key doesn't exist until it's installed, so early values
  sit unreadable-by-the-server anyway.
- Nothing before cutover reads them: the build never decrypts, and the VM/test
  use dummies.
- Several values are rotated at migration (Telegram token, Samba/transmission
  creds) and the Tailscale auth key is ephemeral — filling early = filling twice.

Order at cutover:

1. **(do anytime before)** Add a backup recipient to `.sops.yaml` — a plain age
   key kept in 1Password, or a second device — then
   `sops updatekeys secrets/server.yaml`. Until then the SE key is the only one
   that can decrypt.
2. Add the server's recipient: `ssh-keyscan server | ssh-to-age`, add it to
   `.sops.yaml`, `sops updatekeys secrets/server.yaml`.
3. Rotate + fill real values: `sops secrets/server.yaml`.

## What only cutover can prove

Real ZFS pool import, ACME certificate issuance, Tailscale/split-DNS from off
the LAN, the static IP binding to the real NIC, and first-boot secret decryption
(the host key doesn't exist until install). No pre-check; validated during the
install itself.
