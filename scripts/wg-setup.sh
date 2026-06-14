#!/bin/bash
# wg-setup.sh — WireGuard VPN installation, key generation, and QR code setup
#
# Called in two modes:
#   1. Install mode (this file's own name): full install + first-boot config
#   2. Regen mode (called as regen-vpn-keys.sh): regenerate keys and configs only
#
# Port configuration:
#   WG_PORT env var controls the listen port (default: 51820).
#   Alternatives for restrictive networks:
#     443/UDP  — blends with HTTPS traffic
#     53/UDP   — blends with DNS (not recommended; breaks outbound DNS)
#   Set WG_PORT before running: WG_PORT=443 /root/regen-vpn-keys.sh

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# WireGuard listen port — default 51820, configurable via environment
WG_PORT="${WG_PORT:-51820}"

# WireGuard server address space
WG_SERVER_IPV4="10.2.53.1"
WG_SERVER_IPV6="fc10:253::1"
WG_NET_IPV6="fc10:253::/32"

# iptables interface for masquerade — the public-facing interface
ETH_IFACE="${ETH_IFACE:-eth0}"

# -----------------------------------------------------------------------
# wg_conf: generate WireGuard server and client configurations
#   $1: number of client configs to generate (default: 1)
#   $2: print full config text (true/false, default: true)
# -----------------------------------------------------------------------
wg_conf() {
    local nconfs="${1:-1}"
    local print_conf="${2:-true}"

    # Prefer IPv6 public address; fall back to IPv4 if unavailable.
    local server_ip
    server_ip="$(ip -6 a s scope global "${ETH_IFACE}" \
        | grep 'inet6 ' \
        | awk -F'[ \t/]+' '{print $3}' \
        | head -1)"
    if [[ -n "${server_ip}" ]]; then
        server_ip="[${server_ip}]"
    else
        server_ip="$(ip -4 a s scope global "${ETH_IFACE}" \
            | grep 'inet ' \
            | grep -v 'inet 10\.' \
            | awk -F'[ \t/]+' '{print $3}' \
            | head -1)"
    fi

    # Generate server keypair
    local pvk spbk
    pvk="$(wg genkey)"
    spbk="$(echo -n "${pvk}" | wg pubkey)"

    # Build server config with PostUp/PreDown masquerade hooks.
    # PostUp adds iptables rules when wg0 comes up; PreDown removes them.
    local wg0_conf
    wg0_conf="[Interface]
Address = ${WG_SERVER_IPV4}/24, ${WG_SERVER_IPV6}/32
ListenPort = ${WG_PORT}
PrivateKey = ${pvk}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o ${ETH_IFACE} -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${ETH_IFACE} -j MASQUERADE
PreDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o ${ETH_IFACE} -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${ETH_IFACE} -j MASQUERADE
"

    local output=""
    local i
    for i in $(seq "${nconfs}"); do
        # Generate per-client keypair and pre-shared key (PSK).
        # PSK provides an additional symmetric encryption layer, protecting
        # against quantum computing attacks on the key exchange.
        local cpvk cpbk psk
        cpvk="$(wg genkey)"
        cpbk="$(echo -n "${cpvk}" | wg pubkey)"
        psk="$(wg genpsk)"

        local addrs="${WG_SERVER_IPV4%.*}.$((i+1))/32, ${WG_SERVER_IPV6%::*}::$((i+1))/128"

        # Base client config (shared between DNS-only and full-tunnel variants)
        local base_conf
        base_conf="[Interface]
Address = ${WG_SERVER_IPV4%.*}.$((i+1))/32, ${WG_SERVER_IPV6%::*}::$((i+1))/128
DNS = ${WG_SERVER_IPV4}, ${WG_SERVER_IPV6}
PrivateKey = ${cpvk}

[Peer]
Endpoint = ${server_ip}:${WG_PORT}
PersistentKeepalive = 25
PublicKey = ${spbk}
PresharedKey = ${psk}"

        # DNS-only VPN: only DNS queries go through the tunnel.
        # Client traffic uses the ISP connection; IP is not masked.
        local dns_only="${base_conf}
AllowedIPs = ${WG_SERVER_IPV4}/32, ${WG_SERVER_IPV6%::*}::1/128"

        # Full VPN: all traffic (IPv4 and IPv6) routes through the tunnel.
        # Prevents DNS leaks and masks the client IP address.
        local full_vpn="${base_conf}
AllowedIPs = 0.0.0.0/0, ::/0"

        output="${output}
Client ${i} — scan one or both QR codes below:

                        >> DNS Only VPN <<
$(echo "${dns_only}" | qrencode -t utf8)
$(if "${print_conf}"; then echo "${dns_only}"; fi)

                          >> Full VPN <<
$(echo "${full_vpn}" | qrencode -t utf8)
$(if "${print_conf}"; then echo "${full_vpn}"; fi)
"
        # Add peer to server config
        wg0_conf="${wg0_conf}
[Peer]
PublicKey = ${cpbk}
PresharedKey = ${psk}
AllowedIPs = ${addrs}
"
    done

    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
    printf '%s' "${wg0_conf}" > /etc/wireguard/wg0.conf
    chmod 600 /etc/wireguard/wg0.conf

    systemctl enable wg-quick@wg0.service
    systemctl daemon-reload
    systemctl start wg-quick@wg0 || systemctl restart wg-quick@wg0

    printf '%s' "${output}"
}

# -----------------------------------------------------------------------
# Regen mode: called as regen-vpn-keys.sh to regenerate all keys
# -----------------------------------------------------------------------
nconfs="${1:-1}"
if [[ -n "${nconfs//[0-9]/}" ]] || [[ "${nconfs}" -lt 1 ]]; then
    printf 'Cannot create "%s" configs; specify integer >= 1.\n' "${nconfs}"
    exit 1
fi

if [[ "$(basename "${0}")" == 'regen-vpn-keys.sh' ]]; then
    wg_conf "${nconfs}"
    # Remove old motd QR codes; new ones are printed directly to terminal
    rm -f /etc/update-motd.d/99-getting-started
    exit 0
fi


# -----------------------------------------------------------------------
# Install mode: full WireGuard install and first-boot configuration
# -----------------------------------------------------------------------

echo "STEP 1: Install WireGuard ..."
apt-get -qqy update
apt-get -qqy -o Dpkg::Options::="--force-confdef" \
             -o Dpkg::Options::="--force-confold" install \
    qrencode \
    wireguard \
    wireguard-tools
apt-get -qqy autoremove
apt-get -qqy clean
echo "WireGuard installation complete."


echo "STEP 2: Open WireGuard port in ufw ..."
ufw allow "${WG_PORT}/udp" comment 'WireGuard VPN'
# Allow all traffic on the wg0 interface (VPN clients)
ufw allow in on wg0
echo "Firewall rules added."


echo "STEP 3: Configure WireGuard and generate QR codes ..."
# Store QR codes in the motd so they appear on first SSH login.
{
    printf '#!/bin/sh\ncat <<'"'"'MOTD_EOF'"'"'\n'
    printf '=========================================================================\n'
    wg_conf "${nconfs}" false
    printf '\n'
    printf '                                ?\n'
    printf '  Can'"'"'t scan? Multiple clients? Run: /root/regen-vpn-keys.sh <NUM>\n'
    printf '=========================================================================\n'
    printf 'MOTD_EOF\n'
} > /etc/update-motd.d/99-getting-started
chmod 700 /etc/update-motd.d/99-getting-started
echo "WireGuard configuration complete."


echo "STEP 4: Update README ..."
touch /root/README

cat <<EOF >> /root/README

=====================================
 WIREGUARD VPN
=====================================

WireGuard is the VPN software. Donate: https://wireguard.com/donations

Listen port: ${WG_PORT}
Server IPv4: ${WG_SERVER_IPV4}/24
Server IPv6: ${WG_SERVER_IPV6}/32

Two VPN modes are available per client:

  DNS Only VPN
    Only DNS queries route through the tunnel. Ad blocking works;
    the client IP is NOT masked. Use on trusted networks.
    AllowedIPs = ${WG_SERVER_IPV4}/32, ${WG_SERVER_IPV6%::*}::1/128

  Full VPN (recommended for untrusted networks)
    All IPv4 and IPv6 traffic routes through the tunnel.
    Prevents DNS leaks and masks the client IP.
    AllowedIPs = 0.0.0.0/0, ::/0

Regenerate all keys and configs:
    /root/regen-vpn-keys.sh <NUM_CLIENTS>
    e.g.: /root/regen-vpn-keys.sh 3

WARNING: All clients must re-scan QR codes after key regeneration.

Port alternatives (if ${WG_PORT} is blocked):
    443/UDP  — set WG_PORT=443 before running regen-vpn-keys.sh
    53/UDP   — use only if 443 is also blocked

Pre-shared keys are generated per client for post-quantum protection.

IPv6 leak prevention:
    The Full VPN config routes ::/0 through the tunnel, which prevents
    IPv6 leaks. On the server, public IPv6 forwarding is enabled for
    the tunnel. If your ISP does not support IPv6, the IPv6 WireGuard
    subnet (${WG_NET_IPV6}) is still functional within the VPN.

EOF
echo "README update complete."

echo "WireGuard setup complete."
