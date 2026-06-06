#!/bin/bash
# ssh-lock.sh — block SSH access during image first-boot setup
#
# Appends a Match block to /etc/ssh/sshd_config that displays a message
# and exits immediately. Removed by ssh-unlock.sh when setup is complete.

set -euo pipefail

echo "Locking SSH during system setup ..."
cat >> /etc/ssh/sshd_config <<'EOM'
Match User root
    ForceCommand printf "Setup in progress. Retry in a few minutes.\nIf connections are repeatedly refused, the firewall may be rate-limiting you.\nWait 60 seconds and try again.\n"; false
EOM
systemctl restart ssh
echo "SSH locked."
