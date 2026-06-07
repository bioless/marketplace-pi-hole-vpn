# Spec: Unbound service check cleanup

Status: ready
Owner: you
Related: proposals/005-unbound-service-check.md

## Context

`scripts/unbound-setup.sh` STEP 3 verifies Unbound is running using a `sleep 2` followed by `drill` or `dig` DNS query tests. Three problems make this check unreliable: (1) `sleep 2` is unnecessary because `systemctl restart` already waits for the service to reach active state; (2) neither `drill` nor `dig` is installed on a stock Debian 12 image, so both commands exit 127 and the warning fires on every deployment regardless of Unbound's actual state; (3) `private-address: fd00::/8` in the Unbound config is redundant because `fc00::/7` already covers the full range.

## Goal

Replace the unreliable drill/dig verification with a `systemctl is-active` check, make startup failure a hard error, remove the unnecessary sleep, and drop the redundant private-address entry.

## Scope

In scope:
- Remove `sleep 2` from STEP 3
- Replace the drill/dig conditional with `systemctl is-active --quiet unbound`
- Make Unbound startup failure a hard error (exit 1)
- Remove `private-address: fd00::/8` from the Unbound config heredoc

Out of scope (do not build):
- Any change to the Unbound config beyond removing the redundant line
- Any change to how `unbound` is installed (STEP 1) or configured (STEP 2)
- Installing `dnsutils` or `ldnsutils` for query-level verification

## Design

STEP 3 in `unbound-setup.sh` replaces the current block with:

```bash
echo "STEP 3: Verify Unbound is running ..."
if ! systemctl is-active --quiet unbound; then
    echo "ERROR: Unbound failed to start. Check 'systemctl status unbound'."
    exit 1
fi
echo "Unbound is running."
```

`systemctl is-active --quiet unbound` returns 0 when the service is in the `active` state and non-zero otherwise. It is always available on Debian 12 (systemd), requires no external tools, and tests actual service state rather than a single DNS resolution attempt. `systemctl restart unbound` (called in STEP 2) already waits for the service to reach active state before returning, so no sleep is needed before the check.

A failed Unbound start is a hard error because all DNS resolves through Unbound. Without it, Pi-hole has no upstream resolver, and the core stack purpose is broken.

The `private-address: fd00::/8` line in the heredoc that writes `/etc/unbound/unbound.conf.d/pi-hole.conf` is deleted. The `fc00::/7` entry already covers the entire ULA block, making `fd00::/8` dead config.

Invariants this must not break:
- No hardcoded secrets: unchanged.
- shellcheck clean: `systemctl is-active --quiet unbound` with `|| exit 1` is shellcheck-clean bash.
- Admin UI on wg0: unchanged.

## Files to change

| File | Change |
| --- | --- |
| `scripts/unbound-setup.sh` | STEP 3: remove sleep, replace drill/dig block with systemctl check, exit 1 on failure; heredoc: remove `private-address: fd00::/8` |

New files: none.

## Validation

The change is done when `./validate.sh` exits 0 AND the checks below pass.

Feature-specific checks:
- [ ] No sleep in the script:
  ```
  grep -c 'sleep' scripts/unbound-setup.sh
  # expect: 0
  ```
- [ ] No drill or dig references:
  ```
  grep -c 'drill\|dig' scripts/unbound-setup.sh
  # expect: 0
  ```
- [ ] No redundant private-address line:
  ```
  grep 'fd00::/8' scripts/unbound-setup.sh
  # expect: no output
  ```
- [ ] systemctl check is present and fails hard:
  ```
  grep 'systemctl is-active.*unbound' scripts/unbound-setup.sh
  # expect: one matching line
  grep 'exit 1' scripts/unbound-setup.sh
  # expect: at least one matching line
  ```

## Failure modes to handle

- Unbound not active after `systemctl restart` : exit 1 with a clear message pointing to `systemctl status unbound`
- `systemctl` returns active but Unbound is not ready to serve : acceptable; the check confirms service state, not query-level readiness, which is sufficient for setup verification

## Acceptance criteria

- [ ] `sleep 2` is removed from STEP 3
- [ ] The drill/dig conditional is removed
- [ ] `systemctl is-active --quiet unbound` is the verification check
- [ ] Unbound startup failure exits 1 with a clear error message
- [ ] `private-address: fd00::/8` is absent from the Unbound config heredoc
- [ ] `shellcheck -x scripts/unbound-setup.sh` passes
- [ ] `./validate.sh` exits 0
- [ ] No new external package dependency added

## Task checklist

1. [ ] In the Unbound config heredoc, delete the `private-address: fd00::/8` line
2. [ ] In STEP 3, delete `sleep 2`
3. [ ] In STEP 3, replace the drill/dig `if/else` block with the `systemctl is-active --quiet unbound` check and `exit 1` on failure
4. [ ] Run `./validate.sh`, reach exit 0
5. [ ] Run the feature-specific grep checks above
