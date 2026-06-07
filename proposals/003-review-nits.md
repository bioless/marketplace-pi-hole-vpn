# Proposal: Review nits from modernization commit

Status: proposed
Author: agent
Date: 2026-06-07

Grouped nits from the /review of the modernization commit (Debian 12, Pi-hole v6, security hardening). None blocks a ship individually, but they are captured here so nothing is lost.

---

## Nit 1: Redundant private-address in unbound config

**File:** `scripts/unbound-setup.sh`

`/etc/unbound/unbound.conf.d/pi-hole.conf` lists both:

```
private-address: fc00::/7
private-address: fd00::/8
```

`fc00::/7` already covers `fd00::/8` (the /7 prefix includes both `fc00::/8` and `fd00::/8`). The `fd00::/8` line is redundant. Remove it.

**One-line fix:** delete the `private-address: fd00::/8` line from unbound-setup.sh.

---

## Nit 2: Fixed sleep before DNS verification

**File:** `scripts/unbound-setup.sh`

`sleep 2` before the DNS verification check is a fixed wait. On a slow disk or heavily loaded build host, Unbound may not be ready in 2 seconds. On a fast system, 2 seconds is wasted. Consider replacing with a poll loop (`until unbound-checkconf ...; do sleep 1; done`) or using `systemctl is-active --wait` to wait for the service to stabilize.

**Effort:** small.

**Note:** Nits 2 and 3 are better addressed together. The optimal path — replacing the entire `sleep` + drill/dig block with `systemctl is-active --quiet unbound` — eliminates both issues in fewer lines. See proposal 005.

---

## Nit 3: DNS verification warning fires when drill/dig not installed

**File:** `scripts/unbound-setup.sh`

The verification block:

```bash
if ! drill @127.0.0.1 -p 5335 pi-hole.net &>/dev/null \
        && ! dig @127.0.0.1 -p 5335 pi-hole.net +short &>/dev/null; then
    echo "Warning: Unbound DNS test query failed. ..."
else
    echo "Unbound DNS resolution verified."
fi
```

On a fresh Debian 12 image, neither `drill` (from `ldnsutils`) nor `dig` (from `dnsutils`) is installed. Both commands exit 127 (command not found). The `!` negation makes each test succeed, so the `if` branch fires and prints the warning on every deployment, even when Unbound is running correctly. This makes the warning hard to distinguish from a real failure.

Fix: check for command availability before running the test, or install `dnsutils` as part of unbound-setup.sh. Alternatively, skip the verification entirely and rely on `systemctl is-active unbound`.

**Effort:** small.

**Note:** See proposal 005 for the combined fix that addresses Nits 2 and 3 together.

---

## Invariants touched

None. All three are cosmetic or reliability nits with no security impact.

## Decision (human fills this in)

- [ ] promote to spec
- [ ] defer
- [x] decline

Notes: Nit 1 (redundant fd00::/8) and Nits 2+3 (sleep + drill/dig verification) are addressed together in proposal 005 with a simpler approach than what is described here. This proposal is superseded by 005.
