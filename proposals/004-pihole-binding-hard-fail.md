# Proposal: Make Pi-hole wg0 binding a hard requirement

Status: proposed
Author: agent
Date: 2026-06-07

## Problem or opportunity

`scripts/pihole-setup.sh` uses a two-path approach to bind the Pi-hole web server to the WireGuard interface:

1. **Primary:** `pihole-FTL --config webserver.port "${WEB_BIND}"` (Pi-hole v6 API)
2. **Fallback:** An awk script that edits `/etc/pihole/pihole.toml` directly

The awk fallback is broken (checks both TOML section header and key on the same line; they are on separate lines, so the condition never matches). Beyond that, the fallback is the wrong tool: if `pihole-FTL --config` is unavailable, the Pi-hole v6 installation itself is broken. No awk rewrite can fix an incomplete installation.

The primary path, when it succeeds, produces the correct binding. When it fails, the fallback silently does nothing useful, and Pi-hole may bind to `0.0.0.0:8080`. The ufw rule in security-setup.sh (`ufw allow in on wg0 to any port 8080`) maintains the network-level access restriction, but the application-level binding is not enforced.

## Why it matters

Defense-in-depth is better than a single network-layer guard. The application-level binding is the primary CLAUDE.md invariant ("Admin UI binds to wg0 only"). Silently continuing when it cannot be confirmed is worse than surfacing the failure. An operator who sees the Droplet complete setup without error has no signal that the binding is wrong.

Removing the broken fallback also simplifies the script by roughly 15 lines.

## Rough approach

Remove the awk fallback block entirely. Convert the `pihole-FTL --config` calls from soft failures to hard errors:

```bash
pihole-FTL --config webserver.port "${WEB_BIND}" \
    || { echo "ERROR: could not bind Pi-hole web server to wg0 — aborting"; exit 1; }

pihole-FTL --config dns.queryLogging false 2>/dev/null || true

pihole-FTL --config dns.upstreams '["127.0.0.1#5335"]' \
    || { echo "ERROR: could not configure Pi-hole upstream DNS — aborting"; exit 1; }
```

Only the binding (`webserver.port`) and upstream DNS (`dns.upstreams`) are hard errors — these are security and functionality invariants. `dns.queryLogging` is a preference and can remain a soft failure.

After the `pihole-FTL --config` calls, remove the `if [[ -f /etc/pihole/pihole.toml ]]; then ... fi` fallback block in full.

## Rough effort

small — remove ~15 lines and change two `|| true` to `|| { ...; exit 1; }` patterns.

## Invariants touched

Admin UI binds to wg0 only. This proposal strengthens enforcement of that invariant by surfacing a failure rather than silently allowing a misconfigured state.

## Clarifications (resolved 2026-06-07)

**Post-set verification:** After `pihole-FTL --config webserver.port` succeeds, grep pihole.toml for the expected binding string to confirm the value was written. This catches a silent config-write failure without re-introducing the awk fallback. If the grep fails, exit 1.

```bash
pihole-FTL --config webserver.port "${WEB_BIND}" \
    || { echo "ERROR: pihole-FTL --config webserver.port failed"; exit 1; }
grep -q "${WG_IP}:8080" /etc/pihole/pihole.toml \
    || { echo "ERROR: webserver binding not found in pihole.toml after setting"; exit 1; }
```

**dns.upstreams:** Also a hard error (exit 1 on failure). Only `dns.queryLogging` remains a soft failure.

**Restart block:** Keep the existing restart logic (`systemctl restart pihole-FTL || systemctl restart pihole`) as-is after config changes.

## Decision (human fills this in)

- [x] promote to spec
- [ ] defer
- [ ] decline

Notes: Promoted to specs/001-pihole-binding-hard-fail.md.
