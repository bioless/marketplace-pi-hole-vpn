#!/bin/bash
# validate.sh - closed-loop quality gate for marketplace-pi-hole-vpn
#
# Checks (in order):
#   1. shellcheck on all scripts/*.sh (requires: apt-get install shellcheck)
#   2. terraform fmt -check and terraform validate (if terraform is installed)
#   3. packer validate (if packer is installed and DO_PAT env var is set)
#   4. Secret scan: no hardcoded WireGuard keys or plaintext passwords
#
# Exit 0 = all checks pass. Non-zero = first failure, with reason.
# Run this before every commit. No exceptions.

set -euo pipefail

pass() { printf 'PASS: %s\n' "$*"; }
skip() { printf 'SKIP: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# --- shellcheck ---
# shellcheck itself is the linter for all shell scripts.
# Requires: apt-get install shellcheck
echo "--- shellcheck ---"
if ! command -v shellcheck &>/dev/null; then
    fail "shellcheck not installed (apt-get install shellcheck)"
fi
# image-check.sh and image-cleanup.sh are DigitalOcean-supplied tools; skip them.
find scripts/ -name '*.sh' \
    ! -name 'image-check.sh' \
    ! -name 'image-cleanup.sh' \
    | sort | xargs shellcheck -x \
    || fail "shellcheck found issues in scripts/ — fix before committing"
pass "shellcheck"

# --- terraform ---
echo "--- terraform ---"
if command -v terraform &>/dev/null; then
    terraform -chdir=terraform fmt -check -diff \
        || fail "terraform fmt: run 'terraform -chdir=terraform fmt' to fix formatting"
    pass "terraform fmt"
    terraform -chdir=terraform validate \
        || fail "terraform validate failed"
    pass "terraform validate"
else
    skip "terraform not installed"
fi

# --- packer ---
# Requires DO_PAT env var to authenticate against DigitalOcean for validation.
echo "--- packer ---"
if command -v packer &>/dev/null; then
    if [[ -n "${DO_PAT:-}" ]]; then
        packer validate -var "do_token=${DO_PAT}" main.pkr.hcl \
            || fail "packer validate failed"
        pass "packer validate"
    else
        skip "packer validate (set DO_PAT env var to enable)"
    fi
else
    skip "packer not installed"
fi

# --- secret scan ---
# WireGuard private keys and PSKs are 44-character base64 strings generated
# at runtime by wg genkey / wg genpsk. They must never be hardcoded in scripts.
# Admin passwords are generated at first boot — also never in scripts.
echo "--- secret scan ---"

# Check for hardcoded WireGuard keys: a literal assignment to PrivateKey or
# PresharedKey followed by a base64 string (not a shell variable or wg command).
if grep -rn 'PrivateKey = [A-Za-z0-9+/]\{40,\}' scripts/ 2>/dev/null; then
    fail "hardcoded WireGuard PrivateKey found in scripts/ — keys must be generated at runtime"
fi
if grep -rn 'PresharedKey = [A-Za-z0-9+/]\{40,\}' scripts/ 2>/dev/null; then
    fail "hardcoded WireGuard PresharedKey found in scripts/ — keys must be generated at runtime"
fi

# Check that no script contains a hardcoded password literal (not a variable
# assignment that generates one from /dev/urandom or similar).
if grep -rn 'PIHOLE_PASS\s*=\s*"[^$]' scripts/ 2>/dev/null \
        | grep -v '#'; then
    fail "hardcoded Pi-hole password found in scripts/ — passwords must be random"
fi

pass "secret scan"

echo ""
pass "All checks passed. Safe to commit."
exit 0
