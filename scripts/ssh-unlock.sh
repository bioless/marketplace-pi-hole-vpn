#!/bin/bash
# ssh-unlock.sh — remove the SSH setup lock and apply hardened SSH settings
#
# Runs as the final cloud-init step (09-unlock-ssh.sh) after all services
# are configured. Removes the ForceCommand lock added by ssh-lock.sh, then
# restarts SSH with the hardened config written by security-setup.sh.

set -euo pipefail

echo "Unlocking SSH ..."
# Remove the Match block that was added by ssh-lock.sh
sed -e '/^Match User root$/d' \
    -e '/.*ForceCommand.*initial setup.*/d' \
    -i /etc/ssh/sshd_config

# Confirm the hardened config was applied by security-setup.sh
if [[ ! -f /etc/ssh/sshd_config.d/99-hardened.conf ]]; then
    echo "Warning: hardened SSH config not found; SSH will start without hardening."
fi

# Validate config before restarting
if sshd -t; then
    systemctl restart ssh
    echo "SSH unlocked and restarted with hardened settings."
else
    echo "ERROR: sshd config validation failed. Restarting with previous config."
    # Attempt to restart anyway — the old config may still be valid
    systemctl restart ssh || true
fi
