#!/bin/bash
# pihole-setup.sh — Pi-hole v6 installation and configuration
#
# Pi-hole v6 uses an embedded FTL web server (no lighttpd).
# Runtime configuration is in /etc/pihole/pihole.toml (TOML format).
# The admin UI is bound to the WireGuard interface (10.2.53.1) only.
# A random admin password is generated and stored at /root/.pihole-admin-pass.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# WireGuard interface IP — must match wg-setup.sh
WG_IP="10.2.53.1"
WG_IP6="fc10:253::1"

echo "STEP 1: Install Pi-hole v6 ..."
mkdir -p /etc/pihole

# setupVars.conf is still read by the Pi-hole installer for interface and
# DNS settings. LIGHTTPD_ENABLED=false tells the installer not to install
# or configure lighttpd. Pi-hole v6 uses the FTL embedded web server.
cat <<EOF > /etc/pihole/setupVars.conf
PIHOLE_INTERFACE=wg0
QUERY_LOGGING=false
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=false
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=single
BLOCKING_ENABLED=true
DNSSEC=true
REV_SERVER=false
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=127.0.0.1#5335
IPV4_ADDRESS=${WG_IP}/24
IPV6_ADDRESS=${WG_IP6}/32
EOF

curl -sSL https://install.pi-hole.net -o /tmp/install-pihole.sh
chmod 700 /tmp/install-pihole.sh
/tmp/install-pihole.sh --unattended
rm -f /tmp/install-pihole.sh
echo "Pi-hole installation complete."


echo "STEP 2: Configure Pi-hole v6 (pihole.toml) ..."
# Bind the admin UI to the WireGuard interface only.
# The port format for the FTL web server is "IP:PORTo" where "o" marks
# the port as HTTP (not HTTPS). This prevents the admin UI from being
# reachable from the public internet.
#
# pihole-FTL --config sets individual keys in /etc/pihole/pihole.toml.

WEB_BIND="${WG_IP}:8080o,${WG_IP}:4443s"

# Bind web server to WireGuard interface only
pihole-FTL --config webserver.port "${WEB_BIND}" 2>/dev/null \
    || echo "Warning: pihole-FTL --config not available; falling back to direct config edit"

# Disable query logging (privacy-first default; user can enable in web UI)
pihole-FTL --config dns.queryLogging false 2>/dev/null \
    || true

# Confirm DNS upstream points to Unbound
pihole-FTL --config dns.upstreams '["127.0.0.1#5335"]' 2>/dev/null \
    || true

# Fallback: if pihole-FTL --config is not available, write pihole.toml directly
# using awk to update the relevant keys.
if [[ -f /etc/pihole/pihole.toml ]]; then
    # Update webserver.port binding
    if ! grep -q "${WG_IP}:8080" /etc/pihole/pihole.toml 2>/dev/null; then
        awk -v bind="${WEB_BIND}" '
            /^[[:space:]]*port[[:space:]]*=/ && /webserver/ { print "  port = \"" bind "\""; next }
            { print }
        ' /etc/pihole/pihole.toml > /tmp/pihole.toml.tmp \
            && mv /tmp/pihole.toml.tmp /etc/pihole/pihole.toml
    fi
fi

# Restart Pi-hole FTL to apply configuration changes
if systemctl is-active --quiet pihole-FTL 2>/dev/null; then
    systemctl restart pihole-FTL
elif systemctl is-active --quiet pihole 2>/dev/null; then
    systemctl restart pihole
fi
echo "Pi-hole v6 configuration complete."


echo "STEP 3: Set random admin password ..."
# Generate a cryptographically random admin password (20 characters).
# Store it in /root/.pihole-admin-pass (mode 0600) for the operator to read.
# Never write this to git or expose it in logs.
ADMIN_PASS="$(tr -dc 'A-Za-z0-9!@#%^' < /dev/urandom | head -c 20)"

# Pi-hole v6: use pihole setpassword command
if command -v pihole &>/dev/null; then
    echo "${ADMIN_PASS}" | pihole setpassword 2>/dev/null \
        || pihole -a -p "${ADMIN_PASS}" 2>/dev/null \
        || echo "Warning: could not set admin password automatically; set it manually with: pihole setpassword"
fi

printf '%s\n' "${ADMIN_PASS}" > /root/.pihole-admin-pass
chmod 600 /root/.pihole-admin-pass
echo "Admin password saved to /root/.pihole-admin-pass (mode 0600)."


echo "STEP 4: Update README ..."
touch /root/README
# Remove any previous Pi-hole section before appending the updated one.
perl -0777 -i -pe 's/\n+#{0,1}[= ]*PIHOLE.*?(?=\n#{0,1}[= ]*(?:WIREGUARD|UNBOUND|$))//s' \
    /root/README 2>/dev/null || true

cat <<'EOF' >> /root/README

=====================================
 PI-HOLE (v6 — embedded web server)
=====================================

Pi-hole blocks ads and trackers network-wide.
Donate: https://pi-hole.net/donate

Admin dashboard (connect to VPN first):
    http://10.2.53.1:8080/admin

Admin password is in /root/.pihole-admin-pass
Reset with: pihole setpassword

Query logging is disabled by default for privacy.
Enable it in the admin UI under Settings > DNS.

Update Pi-hole:
    pihole updatePihole

EOF
echo "README update complete."
