# Proposal: Fix broken awk fallback for pihole.toml webserver binding

Status: proposed
Author: agent
Date: 2026-06-07

## Problem or opportunity

`scripts/pihole-setup.sh` contains an awk fallback that is supposed to update the `webserver.port` key in `/etc/pihole/pihole.toml` when `pihole-FTL --config` is unavailable. The awk pattern is:

```awk
/^[[:space:]]*port[[:space:]]*=/ && /webserver/ { ... }
```

This tries to match both patterns on the **same line**. In TOML format, the section header `[webserver]` and the `port = "..."` key are on separate lines, so the condition is never true. The fallback silently does nothing.

If `pihole-FTL --config webserver.port` fails and the TOML fallback also fails, Pi-hole may bind to `0.0.0.0:8080` instead of `10.2.53.1:8080`. The ufw rule added by security-setup.sh (`ufw allow in on wg0 to any port 8080`) preserves the network-level access restriction, so the CLAUDE.md invariant is maintained via defense-in-depth, but the application-level binding is not enforced.

## Why it matters

Two layers of defense are better than one. If the ufw layer is ever modified or the default-deny policy changes, the application-level binding would be the only guard against the admin UI being reachable from the public interface.

## Rough approach

Replace the single-line awk pattern with a stateful approach that tracks the current TOML section:

```awk
awk -v bind="${WEB_BIND}" '
    /^\[webserver\]/ { in_webserver=1 }
    /^\[/ && !/^\[webserver\]/ { in_webserver=0 }
    in_webserver && /^[[:space:]]*port[[:space:]]*=/ {
        print "  port = \"" bind "\""
        next
    }
    { print }
' /etc/pihole/pihole.toml
```

Alternatively, replace the awk with a `sed` that operates on the pihole.toml file using a range address (`/\[webserver\]/,/\[/`).

## Rough effort

small — one awk block replacement in pihole-setup.sh.

## Invariants touched

Admin UI binds to wg0 only. This proposal strengthens the application-level enforcement of that invariant.

## Decision (human fills this in)

- [ ] promote to spec
- [ ] defer
- [ ] decline

Notes:
