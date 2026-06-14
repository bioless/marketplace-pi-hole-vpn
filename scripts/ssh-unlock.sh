#!/bin/bash
# ssh-unlock.sh — remove the SSH setup lock and apply hardened SSH settings
#
# Runs as the final cloud-init step (09-unlock-ssh.sh) after all services
# are configured. Deletes the drop-in lock file written by ssh-lock.sh,
# then restarts SSH with the hardened config written by security-setup.sh.

set -euo pipefail

echo "Unlocking SSH ..."

# Remove the lock drop-in installed during the Packer image build.
# rm -f is idempotent: succeeds whether or not the file exists.
rm -f /etc/ssh/sshd_config.d/00-lock.conf

# Confirm the hardened config was applied by security-setup.sh
if [[ ! -f /etc/ssh/sshd_config.d/99-hardened.conf ]]; then
    echo "Warning: hardened SSH config not found; SSH will start without hardening."
fi

# Validate config before restarting
if sshd -t; then
    systemctl restart ssh
    echo "SSH unlocked and restarted with hardened settings."
else
    echo "ERROR: sshd config validation failed. Check /etc/ssh/sshd_config.d/"
    exit 1
fi
