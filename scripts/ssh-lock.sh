#!/bin/bash
# ssh-lock.sh — block SSH access during image build
#
# Writes /etc/ssh/sshd_config.d/00-lock.conf with a ForceCommand that
# rejects all connections. Removed at first boot by ssh-unlock.sh.
# The 00- prefix makes this sort before 99-hardened.conf (alphabetical
# include order; in sshd_config, first occurrence of a directive wins).

set -euo pipefail

echo "Locking SSH during system setup ..."
mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/00-lock.conf <<'EOF'
# Temporary lock installed during Packer image build.
# Removed by ssh-unlock.sh on first boot after setup completes.
ForceCommand printf "Setup in progress. Retry in a few minutes.\nIf connections are repeatedly refused, the firewall may be rate-limiting you.\nWait 60 seconds and try again.\n"; false
EOF

sshd -t || { echo "ERROR: sshd config invalid after writing lock file"; exit 1; }
systemctl restart ssh
echo "SSH locked."
