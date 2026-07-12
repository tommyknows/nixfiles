# Integration checks for the homeserver services. `server` runs the full stack
# (vm-common); `outsider` sits on an untrusted subnet to prove the nginx ACL
# denies non-LAN sources.
start_all()

server.wait_for_unit("multi-user.target")

# Emby serves HTTP.
server.wait_for_unit("emby.service")
server.wait_for_open_port(8096)
server.succeed("curl -sf -o /dev/null http://127.0.0.1:8096/")

# Blocky answers, and the split-horizon override points the apex + subdomains at
# the LAN IP.
server.wait_for_unit("blocky.service")
server.wait_for_open_port(53)
server.succeed("dig +short cloud.ramonr.ch @127.0.0.1 | grep -qx 192.168.1.1")
server.succeed("dig +short movies.ramonr.ch @127.0.0.1 | grep -qx 192.168.1.1")

# The *arrs and jackett come up (jackett proves the Mac-only case-hack failure
# does not occur on a case-sensitive Linux store).
for unit in ["radarr", "sonarr", "lidarr", "jackett"]:
    server.wait_for_unit(f"{unit}.service")

# Transmission requires RPC auth: the endpoint answers but rejects unauthenticated.
server.wait_for_unit("transmission.service")
server.wait_for_open_port(9091)
server.succeed(
    "curl -s -o /dev/null -w '%{http_code}' "
    "http://127.0.0.1:9091/transmission/rpc | grep -qx 401"
)

# nginx serves a private vhost to a local (allowed) client. The real cert can't
# issue without the ACME token, so it serves its self-signed fallback (-k).
server.wait_for_unit("nginx.service")
server.wait_for_open_port(443)
code = server.succeed(
    "curl -sk -o /dev/null -w '%{http_code}' "
    "--resolve movies.ramonr.ch:443:127.0.0.1 https://movies.ramonr.ch/"
)
assert code in ("200", "302"), f"expected allow (200/302) from localhost, got {code}"

# Samba is up and its shares are listable (guest list).
server.wait_for_unit("samba-smbd.service")
server.wait_until_succeeds("smbclient -N -L //localhost 2>&1 | grep -q music")

# nginx ACL denies a source outside the LAN/tailnet ranges. `outsider` is on
# 192.168.2.0/24 (not allowed) and reaches the server's vlan-2 address.
outsider.wait_for_unit("multi-user.target")
outsider.succeed(
    "curl -sk -o /dev/null -w '%{http_code}' "
    "--resolve movies.ramonr.ch:443:192.168.2.1 https://movies.ramonr.ch/ | grep -qx 403"
)

# sudo requires a valid TOTP (auth.nix policy: pam_oath requisite + null unix
# password for ramon). A correct current code is accepted; a wrong one is
# refused — proving OATH is genuinely required, not bypassable.
import hmac
import hashlib
import struct
import time


def totp(hexseed: str) -> str:
    counter = struct.pack(">Q", int(time.time()) // 30)
    digest = hmac.new(bytes.fromhex(hexseed), counter, hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    trunc = struct.unpack(">I", digest[offset : offset + 4])[0] & 0x7FFFFFFF
    return "%06d" % (trunc % 1_000_000)


seed = "3132333435363738393031323334353637383930"  # matches vm-common's test seed
server.succeed(f"su ramon -s /bin/sh -c 'sudo -k; echo {totp(seed)} | sudo -S true'")
server.fail("su ramon -s /bin/sh -c 'sudo -k; echo 000000 | sudo -S true'")
