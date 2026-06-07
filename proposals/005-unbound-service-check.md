# Proposal: Replace Unbound DNS verification with systemctl check

Status: proposed
Author: agent
Date: 2026-06-07

## Problem or opportunity

`scripts/unbound-setup.sh` verifies Unbound is running with:

```bash
sleep 2
if ! drill @127.0.0.1 -p 5335 pi-hole.net &>/dev/null \
        && ! dig @127.0.0.1 -p 5335 pi-hole.net +short &>/dev/null; then
    echo "Warning: Unbound DNS test query failed. ..."
else
    echo "Unbound DNS resolution verified."
fi
```

Three problems:

1. **`sleep 2` is unnecessary.** `systemctl restart unbound` waits for the service to reach active state before returning. The sleep adds latency for no reason.

2. **The warning fires on every deployment.** Neither `drill` (from `ldnsutils`) nor `dig` (from `dnsutils`) is installed on a stock Debian 12 image. Both exit 127. The `!` negation makes both conditions succeed, so the `if` branch fires and prints the warning even when Unbound is running correctly.

3. **`private-address: fd00::/8` is redundant.** The Unbound config already lists `private-address: fc00::/7`, which covers the entire `fc00::/7` prefix — including both `fc00::/8` and `fd00::/8`. The `fd00::/8` line is dead.

All three are in `unbound-setup.sh` and are addressed together here (supersedes proposal 003).

## Why it matters

The spurious warning makes it impossible to distinguish a real Unbound failure from a normal deployment. An operator checking cloud-init logs would not know whether to act. The redundant `private-address` entry is a minor correctness issue with no security impact.

## Rough approach

Remove `sleep 2`. Replace the drill/dig block with a `systemctl is-active --quiet unbound` check, which is always available, checks the actual service state, and requires no external tools:

```bash
if systemctl is-active --quiet unbound; then
    echo "Unbound is running."
else
    echo "Warning: Unbound failed to start. Check 'systemctl status unbound'."
fi
```

Remove the `private-address: fd00::/8` line from the Unbound config heredoc.

## Rough effort

small — remove ~8 lines, replace with ~4, delete one config line.

## Invariants touched

None. No security impact. The Unbound config change (removing a redundant entry) does not change behavior.

## Decision (human fills this in)

- [ ] promote to spec
- [ ] defer
- [ ] decline

Notes:
