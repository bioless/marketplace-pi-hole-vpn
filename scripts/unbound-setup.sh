#!/bin/bash
# unbound-setup.sh — recursive DNS resolver installation and configuration
#
# Unbound listens on 127.0.0.1:5335 and acts as the upstream resolver for
# Pi-hole. It performs full DNSSEC validation and hides version/identity
# information to reduce DNS-based fingerprinting.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "STEP 1: Install Unbound ..."
apt-get -qqy update
apt-get -qqy -o Dpkg::Options::="--force-confdef" \
             -o Dpkg::Options::="--force-confold" install \
    unbound
apt-get -qqy autoremove
apt-get -qqy clean
echo "Unbound installation complete."


echo "STEP 2: Configure Unbound ..."
mkdir -p /etc/unbound/unbound.conf.d

cat <<'EOF' > /etc/unbound/unbound.conf.d/pi-hole.conf
server:
    # Verbosity: 0 = errors only
    verbosity: 0

    # Bind to localhost only — Unbound is not a public resolver
    interface: 127.0.0.1
    port: 5335

    # Protocol support
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no

    # Access control: allow only localhost
    access-control: 127.0.0.0/8 allow
    access-control: 0.0.0.0/0 deny
    access-control: ::1 allow
    access-control: ::0/0 deny

    # Fingerprint reduction: do not reveal software version or hostname
    hide-identity: yes
    hide-version: yes

    # DNSSEC hardening
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-algo-downgrade: yes
    harden-large-queries: yes

    # Prevent DNS-0x20 randomisation (causes issues with some resolvers)
    use-caps-for-id: no

    # EDNS buffer size per RFC 4960 / RIPE-recommended value
    edns-buffer-size: 1232

    # Performance
    prefetch: yes
    prefetch-key: yes
    num-threads: 1
    so-rcvbuf: 1m

    # Block private address ranges from being returned by upstream resolvers
    # (prevents DNS rebinding attacks)
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fc00::/7
    private-address: fe80::/10

    # Cache settings
    cache-max-ttl: 86400
    cache-min-ttl: 0
EOF

# Disable the default Unbound service if it conflicts with our config
systemctl enable unbound
systemctl restart unbound
echo "Unbound configuration complete."


echo "STEP 3: Verify Unbound is running ..."
# Give Unbound a moment to start and load root hints
sleep 2
if ! drill @127.0.0.1 -p 5335 pi-hole.net &>/dev/null \
        && ! dig @127.0.0.1 -p 5335 pi-hole.net +short &>/dev/null; then
    echo "Warning: Unbound DNS test query failed. Check 'systemctl status unbound'."
else
    echo "Unbound DNS resolution verified."
fi


echo "STEP 4: Update README ..."
touch /root/README

cat <<'EOF' >> /root/README

=====================================
 UNBOUND (recursive DNS resolver)
=====================================

Unbound resolves DNS queries locally without relying on external
resolvers like 8.8.8.8 or 1.1.1.1. It performs full DNSSEC
validation and hides version/identity information.

Configuration: /etc/unbound/unbound.conf.d/pi-hole.conf
Listens on:    127.0.0.1:5335

Donate: https://nlnetlabs.nl/funding/

EOF
echo "README update complete."

echo "Unbound setup complete."
