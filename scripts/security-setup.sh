#!/bin/bash
# security-setup.sh — SSH daemon hardening and fail2ban configuration
#
# Runs as cloud-init step 05-setup-security.sh, after all services are
# installed. SSH hardening is applied here rather than in system-setup.sh
# so it runs after the SSH lock (which blocks access during setup) and
# can reference the final service state.
#
# SSH hardening applied:
#   - Key-only authentication (PasswordAuthentication no)
#   - Root login with keys only (PermitRootLogin prohibit-password)
#   - Idle timeout after 10 minutes (ClientAliveInterval/CountMax)
#   - Restricted ciphers and MACs
#
# fail2ban protects SSH against brute-force attempts.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "STEP 1: Harden SSH daemon configuration ..."
# Write a hardened sshd_config snippet. The main /etc/ssh/sshd_config
# uses Include, so this drop-in takes precedence without touching the
# base config (idempotent and upgrade-safe).
mkdir -p /etc/ssh/sshd_config.d

cat <<'EOF' > /etc/ssh/sshd_config.d/99-hardened.conf
# Key-only authentication — password login is disabled
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# Root login with SSH keys is allowed; password login for root is not.
# This preserves DigitalOcean's key-based root access workflow while
# preventing brute-force password attacks against root.
PermitRootLogin prohibit-password

# Idle session timeout: disconnect after 10 minutes of inactivity
# (300 seconds * 2 checks = 600 seconds = 10 minutes)
ClientAliveInterval 300
ClientAliveCountMax 2

# Restrict to known-safe key exchange, cipher, and MAC algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

# Disable unused authentication methods
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*

# Log authentication attempts
LogLevel VERBOSE
EOF

# Validate the config before restarting
sshd -t -f /etc/ssh/sshd_config \
    || { echo "ERROR: sshd config validation failed; reverting hardened config"; \
         rm -f /etc/ssh/sshd_config.d/99-hardened.conf; exit 1; }
echo "SSH hardening applied."


echo "STEP 2: Configure fail2ban for SSH ..."
# fail2ban monitors /var/log/auth.log and bans IPs with repeated failed
# login attempts. The SSH jail bans after 5 failures within 10 minutes,
# for 1 hour.
mkdir -p /etc/fail2ban

cat <<'EOF' > /etc/fail2ban/jail.d/ssh-hardened.conf
[DEFAULT]
# Ban IPs for 1 hour after 5 failures within 10 minutes
bantime = 3600
findtime = 600
maxretry = 5
backend = auto

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 5
EOF

systemctl enable fail2ban
systemctl restart fail2ban
echo "fail2ban configured."


echo "STEP 3: Disable unused system services ..."
# Disable services that are unnecessary on a VPN-only server and
# represent potential attack surface.
for svc in avahi-daemon cups bluetooth; do
    if systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
        systemctl disable --now "${svc}" 2>/dev/null || true
        echo "Disabled: ${svc}"
    fi
done
echo "Unused services disabled."


echo "STEP 4: Configure Pi-hole admin access via WireGuard ..."
# Pi-hole admin UI is already bound to the WireGuard IP by pihole-setup.sh.
# This step opens the admin port in ufw on the wg0 interface only.
# The public interface (eth0) does not allow port 8080 or 4443.
ufw allow in on wg0 to any port 8080 proto tcp comment 'Pi-hole admin (wg0 only)'
ufw allow in on wg0 to any port 4443 proto tcp comment 'Pi-hole admin HTTPS (wg0 only)'
echo "Pi-hole admin port opened on wg0 interface."

echo "Security setup complete."
