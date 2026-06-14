# Pi-hole VPN

A hardened, privacy-focused VPN with built-in ad blocking.

**Stack:** Pi-hole v6 (ad blocking) + WireGuard (VPN) + Unbound (recursive DNS)

**OS:** Debian 12 (Bookworm)

No upstream DNS servers. All DNS resolves locally via Unbound, then filters
through Pi-hole. Full-tunnel mode routes all traffic through the VPN.

---

## Quick Start

1. Create a Droplet from the marketplace image (or build your own with Packer)
2. SSH in: `ssh root@<droplet-ip>`
3. Wait for first-boot setup to complete (2-5 minutes; progress visible in `/var/log/cloud-init-output.log`)
4. Scan the QR codes shown in the terminal from the [WireGuard app](https://www.wireguard.com/install/)
5. Connect and browse

**Admin UI** (connect to VPN first): `http://10.2.53.1:8080/admin`

**Admin password** is in `/root/.pihole-admin-pass` on the Droplet (auto-generated at first boot).

---

## VPN Modes

Two configs are generated per client:

| Mode | AllowedIPs | Use When |
| --- | --- | --- |
| **DNS Only** | `10.2.53.1/32, fc10:253::1/128` | Trusted network, only need ad blocking |
| **Full VPN** | `0.0.0.0/0, ::/0` | Untrusted network, full privacy |

Full VPN routes all IPv4 and IPv6 traffic through the tunnel, preventing DNS leaks
and masking your IP. Recommended for untrusted networks (hotels, airports, coffee shops).

---

## Security Hardening

| Area | What Is Applied |
| --- | --- |
| SSH | Key-only auth (`PasswordAuthentication no`), root with key only (`PermitRootLogin prohibit-password`), 10-min idle timeout, restricted ciphers |
| Firewall | ufw default-deny inbound; only SSH (22/tcp) and WireGuard (UDP) allowed from public |
| Pi-hole admin | Bound to WireGuard interface (`10.2.53.1:8080`) only; not reachable from public internet |
| DNS | Unbound hides version and identity; DNSSEC validation; no external resolver |
| Brute force | fail2ban: 5 failures within 10 min = 1-hour ban |
| Auto-updates | `unattended-upgrades` applies security patches automatically |
| sysctl | Source routing disabled, ICMP redirects disabled, SYN cookies enabled, log martians |
| WireGuard | Per-peer pre-shared key (PSK) for quantum resistance |

---

## WireGuard Configuration

### Default port

Port: **51820/UDP**

If 51820 is blocked, alternative ports can be used. Set `WG_PORT` before running `regen-vpn-keys.sh`:

```bash
WG_PORT=443 /root/regen-vpn-keys.sh
```

| Port | Notes |
| --- | --- |
| 51820 | WireGuard default |
| 443/UDP | Blends with HTTPS; widely open on restrictive networks |
| 53/UDP | Last resort; may break DNS on some networks |

### Multiple clients

```bash
# Generate configs for 3 clients
/root/regen-vpn-keys.sh 3
```

WARNING: Regenerating keys invalidates all existing client configs. All clients must re-scan.

### Add a single peer without regenerating all keys

```bash
/root/add-vpn-peer.sh [peer-name]
```

The new peer is added to the running WireGuard interface. No restart required.

---

## DNS Architecture

```
Client device
    |
    | (DNS query via WireGuard tunnel)
    v
Pi-hole (10.2.53.1:53)
    |
    | (filtered query — blocks known ad/tracker domains)
    v
Unbound (127.0.0.1:5335)
    |
    | (recursive resolution — walks the DNS tree)
    v
Root nameservers → TLD nameservers → authoritative nameservers
```

No external resolver is involved. Pi-hole blocks known ad and tracker domains.
Unbound resolves everything else directly from the root.

DNSSEC validation is enabled at both Pi-hole and Unbound layers.

---

## IPv6 Leak Prevention

Full VPN mode includes `AllowedIPs = 0.0.0.0/0, ::/0`, which routes all IPv6
traffic through the tunnel. This prevents IPv6 leaks on networks where both
IPv4 and IPv6 are available.

**Client-side:** Confirm your WireGuard app uses `AllowedIPs = 0.0.0.0/0, ::/0`
for the full-tunnel config.

**Browser:** To prevent WebRTC leaks in Firefox:
- Open `about:config`
- Set `media.peerconnection.enabled = false`

Or use uBlock Origin with the "Prevent WebRTC from leaking local IP addresses"
option enabled (uBlock Origin → Settings → Privacy).

---

## Fingerprint Reduction

| Technique | Status |
| --- | --- |
| Local recursive DNS (no 8.8.8.8) | Applied |
| Full-tunnel IPv4+IPv6 | Applied |
| Unbound hides version/identity | Applied |
| Neutral Droplet hostname | Applied |
| Per-peer PSK (post-quantum layer) | Applied |
| Non-default WireGuard port | Optional (set `WG_PORT`) |
| WireGuard obfuscation (udp2raw, AmneziaWG) | Not applied (see proposals/) |

Standard WireGuard handshakes are identifiable by DPI in some environments.
If DPI-based blocking is a concern, see `proposals/` for the AmneziaWG spec candidate.

---

## Building the Image

### Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) >= 1.9
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- A DigitalOcean API token

### Validate scripts locally

```bash
./validate.sh
```

Requires `shellcheck` (`apt-get install shellcheck`).

### Build the Packer snapshot

```bash
packer init .
DO_PAT=<your-api-token> ./validate.sh  # also runs packer validate
packer build -var "do_token=<your-api-token>" main.pkr.hcl
```

Note the snapshot ID from the output (e.g., `marketplace-pi-hole-vpn-1234567890`).

### Provision a Droplet with Terraform

```bash
cd terraform
cat <<EOF > terraform.auto.tfvars
do_token = "<your-api-token>"
image    = "<snapshot-id>"
ssh_keys = [<your-ssh-key-id>]
EOF
terraform init
terraform apply
terraform output droplet_ipv4
```

Get your SSH key ID:
```bash
curl -s -H "Authorization: Bearer <token>" \
    "https://api.digitalocean.com/v2/account/keys" | \
    jq -r '.ssh_keys[] | [.name, .id] | @tsv'
```

Get snapshot IDs:
```bash
curl -s -H "Authorization: Bearer <token>" \
    "https://api.digitalocean.com/v2/images?private=true" | \
    jq -r '.images[] | [.id, .name] | @tsv'
```

---

## Droplet Management

### Key rotation

```bash
# Rotate ALL WireGuard keys (server + all clients)
# All clients must re-scan after this.
/root/regen-vpn-keys.sh [num-clients]
```

### Pi-hole updates

```bash
pihole updatePihole
```

### System updates

```bash
apt update && apt upgrade
# Security patches apply automatically via unattended-upgrades.
```

### Check VPN status

```bash
wg show
```

### View Pi-hole logs

```bash
# Pi-hole v6 uses pihole-FTL
journalctl -u pihole-FTL -f
```

---

## Notes on Droplet Backups

If DigitalOcean backups are enabled, snapshots contain the WireGuard private key.
Options:
- Disable backups and rely on the key rotation script instead.
- If a backup is compromised, run `/root/regen-vpn-keys.sh` to rotate all keys.

---

## Development

See `CLAUDE.md` for the development workflow, conventions, and invariants.

```bash
# Run quality checks before committing
./validate.sh

# Propose an improvement
/suggest

# View the workflow
/workflow
```
