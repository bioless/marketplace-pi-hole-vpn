#!/bin/bash
# add-vpn-peer.sh — add a new WireGuard peer to the running server
#
# Usage:
#   /root/add-vpn-peer.sh [PEER_NAME]
#
# PEER_NAME is used as a comment in wg0.conf and the motd output.
# If not provided, the next available client number is used.
#
# The new peer is added to wg0.conf and the running WireGuard interface.
# A QR code and plain-text config are printed to stdout.
# Rebooting is not required.

set -euo pipefail

WG_CONF="/etc/wireguard/wg0.conf"
WG_IFACE="wg0"

if [[ ! -f "${WG_CONF}" ]]; then
    printf 'Error: %s not found. Run wg-setup.sh first.\n' "${WG_CONF}" >&2
    exit 1
fi

# Determine the next available IP suffix (count existing peers + 1)
EXISTING_PEERS="$(grep -c '^\[Peer\]' "${WG_CONF}" || true)"
NEXT_NUM="$((EXISTING_PEERS + 2))"

# Peer name/comment (optional argument)
PEER_NAME="${1:-client${NEXT_NUM}}"

# Extract server public key from wg0.conf private key
SERVER_PVK="$(grep '^PrivateKey' "${WG_CONF}" | awk '{print $3}' | head -1)"
SERVER_PBK="$(echo -n "${SERVER_PVK}" | wg pubkey)"

# Determine server endpoint (same logic as wg-setup.sh)
ETH_IFACE="${ETH_IFACE:-eth0}"
SERVER_IP="$(ip -6 a s scope global "${ETH_IFACE}" \
    | grep 'inet6 ' \
    | awk -F'[ \t/]+' '{print $3}' \
    | head -1)"
if [[ -n "${SERVER_IP}" ]]; then
    SERVER_IP="[${SERVER_IP}]"
else
    SERVER_IP="$(ip -4 a s scope global "${ETH_IFACE}" \
        | grep 'inet ' \
        | grep -v 'inet 10\.' \
        | awk -F'[ \t/]+' '{print $3}' \
        | head -1)"
fi

# Get listen port from wg0.conf
WG_PORT="$(grep '^ListenPort' "${WG_CONF}" | awk '{print $3}' | head -1)"
WG_PORT="${WG_PORT:-51820}"

# Generate new client keypair and PSK
CLIENT_PVK="$(wg genkey)"
CLIENT_PBK="$(echo -n "${CLIENT_PVK}" | wg pubkey)"
PSK="$(wg genpsk)"

# Allocate client addresses
CLIENT_IPV4="10.2.53.${NEXT_NUM}/32"
CLIENT_IPV6="fc10:253::${NEXT_NUM}/128"
ALLOWED_V4="10.2.53.${NEXT_NUM}/32"
ALLOWED_V6="fc10:253::${NEXT_NUM}/128"

# Build client config (full tunnel)
CLIENT_CONF="[Interface]
Address = ${CLIENT_IPV4}, ${CLIENT_IPV6}
DNS = 10.2.53.1, fc10:253::1
PrivateKey = ${CLIENT_PVK}

[Peer]
Endpoint = ${SERVER_IP}:${WG_PORT}
PersistentKeepalive = 25
PublicKey = ${SERVER_PBK}
PresharedKey = ${PSK}
AllowedIPs = 0.0.0.0/0, ::/0"

# DNS-only variant
DNS_ONLY_CONF="[Interface]
Address = ${CLIENT_IPV4}, ${CLIENT_IPV6}
DNS = 10.2.53.1, fc10:253::1
PrivateKey = ${CLIENT_PVK}

[Peer]
Endpoint = ${SERVER_IP}:${WG_PORT}
PersistentKeepalive = 25
PublicKey = ${SERVER_PBK}
PresharedKey = ${PSK}
AllowedIPs = 10.2.53.1/32, fc10:253::1/128"

# Append peer to wg0.conf
{
    printf '\n[Peer]\n'
    printf '# %s\n' "${PEER_NAME}"
    printf 'PublicKey = %s\n' "${CLIENT_PBK}"
    printf 'PresharedKey = %s\n' "${PSK}"
    printf 'AllowedIPs = %s, %s\n' "${ALLOWED_V4}" "${ALLOWED_V6}"
} >> "${WG_CONF}"

# Add peer to the running WireGuard interface without restarting
wg set "${WG_IFACE}" \
    peer "${CLIENT_PBK}" \
    preshared-key <(printf '%s' "${PSK}") \
    allowed-ips "${ALLOWED_V4},${ALLOWED_V6}"

printf '\n=== New WireGuard peer: %s ===\n\n' "${PEER_NAME}"
printf '--- Full VPN (all traffic through tunnel) ---\n'
echo "${CLIENT_CONF}" | qrencode -t utf8
printf '%s\n\n' "${CLIENT_CONF}"

printf '--- DNS Only VPN ---\n'
echo "${DNS_ONLY_CONF}" | qrencode -t utf8
printf '%s\n' "${DNS_ONLY_CONF}"
