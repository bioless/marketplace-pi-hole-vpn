#!/bin/bash
# system-setup.sh — base OS hardening for the Pi-hole VPN Droplet
#
# Runs twice:
#   1. During Packer build to harden the base image
#   2. As cloud-init 01-setup-system.sh on first Droplet boot
#
# This script is idempotent: re-running it is safe.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "STEP 1: Update system packages ..."
apt-get -qqy update
apt-get -qqy -o Dpkg::Options::="--force-confdef" \
             -o Dpkg::Options::="--force-confold" full-upgrade
echo "System update complete."


echo "STEP 2: Install required packages ..."
apt-get -qqy -o Dpkg::Options::="--force-confdef" \
             -o Dpkg::Options::="--force-confold" install \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    curl \
    wget \
    gnupg2 \
    lsb-release
apt-get -qqy autoremove
apt-get -qqy clean
echo "Package installation complete."


echo "STEP 3: Configure sysctl hardening ..."
cat <<'EOF' > /etc/sysctl.d/99-pihole-vpn.conf
# IP forwarding — required for WireGuard VPN routing
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Disable IP source routing (prevents spoofed packets)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects (prevents routing table manipulation)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Log packets with impossible addresses (RFC 1812 martians)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Protect against SYN flood attacks
net.ipv4.tcp_syncookies = 1

# Disable IPv6 autoconfiguration on the public interface
net.ipv6.conf.eth0.accept_ra = 0
net.ipv6.conf.eth0.autoconf = 0

# Disable kernel pointer exposure
kernel.kptr_restrict = 2

# Restrict dmesg to root
kernel.dmesg_restrict = 1
EOF
sysctl -p /etc/sysctl.d/99-pihole-vpn.conf
echo "sysctl hardening complete."


echo "STEP 4: Configure ufw firewall ..."
# UFW default policies: deny all incoming, allow all outgoing
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH with rate limiting (6 connections per 30 seconds)
ufw limit 22/tcp comment 'SSH (rate limited)'

# Enable UFW IP forwarding so WireGuard can route packets.
# WireGuard masquerade rules are added by wg-setup.sh using
# WireGuard's PostUp/PreDown hooks.
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' \
    /etc/default/ufw

ufw --force enable
echo "Firewall configuration complete."


echo "STEP 5: Configure unattended-upgrades (security channel only) ..."
cat <<'EOF' > /etc/apt/apt.conf.d/50unattended-upgrades-pihole
// Automatically apply security updates only.
// Non-security updates are left for manual review.
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

cat <<'EOF' > /etc/apt/apt.conf.d/20auto-upgrades-pihole
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades
echo "Unattended-upgrades configuration complete."


echo "STEP 6: Set neutral hostname ..."
# Use a generic hostname that does not reveal this server's purpose.
# The user can change this after setup.
hostnamectl set-hostname "node-$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)" \
    || hostnamectl set-hostname "privacy-node"
echo "Hostname set."


echo "STEP 7: Install base README ..."
cat <<'EOF' > /root/README
          Welcome to your Pi-hole VPN Droplet.

Pi-hole (ad blocking) + WireGuard (VPN) + Unbound (recursive DNS)
are installed and configured on first boot. See each section below
for configuration details.

Connect via VPN before accessing the Pi-hole admin UI. The admin UI
is bound to the WireGuard interface only and is not reachable from
the public internet.
EOF
echo "Base README installed."

echo "System setup complete."
