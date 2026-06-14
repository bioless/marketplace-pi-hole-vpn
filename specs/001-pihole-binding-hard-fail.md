# Spec: Pi-hole wg0 binding hard fail

Status: ready
Owner: you
Related: proposals/004-pihole-binding-hard-fail.md

## Context

`scripts/pihole-setup.sh` binds the Pi-hole web server to the WireGuard interface with `pihole-FTL --config webserver.port`, then falls back to a broken awk block if the command fails. The awk pattern checks for both the TOML section header and key on the same line, which never matches, so the fallback silently does nothing. If `pihole-FTL --config` fails, Pi-hole may bind to `0.0.0.0:8080`. The ufw rule in `security-setup.sh` maintains network-level access control, but the application-level binding is not confirmed. The CLAUDE.md invariant "Admin UI binds to wg0 only" is enforced at only one layer when it should be enforced at two.

## Goal

Make the Pi-hole wg0 binding a hard requirement: fail the cloud-init step loudly if the binding cannot be confirmed, and remove the broken fallback.

## Scope

In scope:
- Remove the awk fallback block from `pihole-setup.sh`
- Convert the `pihole-FTL --config webserver.port` call from a soft failure to a hard error
- Add a grep verification that the binding string appears in `pihole.toml` after setting
- Convert the `pihole-FTL --config dns.upstreams` call to a hard error
- Remove `2>/dev/null` suppression from the two hard-error calls so stderr is visible on failure

Out of scope (do not build):
- Any change to the ufw rules in `security-setup.sh`
- Any change to the Pi-hole install step (STEP 1)
- Any change to the admin password generation (STEP 3)

## Design

Two changes to STEP 2 in `pihole-setup.sh`:

1. **Hard-fail the binding call.** Remove the `2>/dev/null || echo "Warning..."` pattern from the `webserver.port` call and replace with `|| { echo "ERROR: ..."; exit 1; }`. Keep stderr visible so the operator sees the actual error.

2. **Verify the binding landed.** After a successful `pihole-FTL --config webserver.port`, grep `pihole.toml` for the expected IP string. If it is absent (indicating a silent config-write failure), exit 1. This check is a one-liner and does not re-introduce any awk.

3. **Hard-fail upstream DNS.** Apply the same pattern to `pihole-FTL --config dns.upstreams`. A wrong upstream means Pi-hole resolves via an external server rather than Unbound, defeating the local DNS architecture.

4. **Keep `dns.queryLogging` soft.** This is a user preference with no security or architecture impact. A failure here does not break the stack.

5. **Remove the awk fallback block in full.** The 12-line `if [[ -f /etc/pihole/pihole.toml ]]; then ... fi` block disappears.

Invariants this must not break:
- Admin UI binds to wg0 only: this spec strengthens enforcement.
- No hardcoded secrets: unchanged.
- shellcheck clean: the replacement patterns (`|| { ...; exit 1; }`) are shellcheck-clean bash.
- Pi-hole v6 pihole.toml only: `pihole-FTL --config` writes to pihole.toml. The awk that directly edited it is removed, not replaced with another direct writer.
- No lighttpd: unchanged.

## Files to change

| File | Change |
| --- | --- |
| `scripts/pihole-setup.sh` | STEP 2: remove 2>/dev/null from binding call, add exit 1 on failure, add grep verification, hard-fail dns.upstreams, remove the 12-line awk fallback block |

New files: none.

## Validation

The change is done when `./validate.sh` exits 0 AND the checks below pass.

Feature-specific checks:
- [ ] No awk block remains in the script:
  ```
  grep -c 'awk' scripts/pihole-setup.sh
  # expect: 0
  ```
- [ ] Hard-error pattern appears for both binding and upstream calls:
  ```
  grep 'exit 1' scripts/pihole-setup.sh
  # expect: at least two lines, one for webserver.port and one for dns.upstreams
  ```
- [ ] Grep verification step is present:
  ```
  grep 'grep -q.*8080.*pihole.toml' scripts/pihole-setup.sh
  # expect: one matching line
  ```

## Failure modes to handle

- `pihole-FTL --config webserver.port` returns non-zero : print error with visible stderr, exit 1
- `pihole-FTL --config webserver.port` returns 0 but binding is absent from pihole.toml : grep check fires, exit 1 with a clear message
- `pihole-FTL --config dns.upstreams` returns non-zero : exit 1 with a clear message
- `pihole-FTL --config dns.queryLogging` fails : continue (not a stack invariant)
- Pi-hole is not yet installed when this step runs : `pihole-FTL` not found, the first hard-fail exits 1 with a visible error

## Acceptance criteria

- [ ] The awk fallback block is gone (zero `awk` occurrences in `pihole-setup.sh`)
- [ ] `pihole-FTL --config webserver.port` failure exits 1 with a visible error
- [ ] A grep check confirms the binding string in `pihole.toml` after setting; failure exits 1
- [ ] `pihole-FTL --config dns.upstreams` failure exits 1 with a visible error
- [ ] `dns.queryLogging` failure is still a soft failure (no exit 1)
- [ ] `shellcheck -x scripts/pihole-setup.sh` passes
- [ ] `./validate.sh` exits 0
- [ ] No new external package dependency added

## Task checklist

All changes are in `scripts/pihole-setup.sh` STEP 2 (lines 59-89). Steps are sequential: each edit shifts line numbers for the next.

1. [ ] `scripts/pihole-setup.sh` line 60-61: remove `2>/dev/null` from the `webserver.port` call and replace `|| echo "Warning: pihole-FTL --config not available; falling back to direct config edit"` with `|| { echo "ERROR: pihole-FTL --config webserver.port failed"; exit 1; }`
2. [ ] `scripts/pihole-setup.sh` immediately after the `webserver.port` call (now line ~62): add `grep -q "${WG_IP}:8080" /etc/pihole/pihole.toml || { echo "ERROR: webserver.port binding absent from pihole.toml after setting"; exit 1; }`
3. [ ] `scripts/pihole-setup.sh` `dns.upstreams` call (~line 68 after prior edits): remove `2>/dev/null` and change `|| true` to `|| { echo "ERROR: pihole-FTL --config dns.upstreams failed"; exit 1; }`
4. [ ] `scripts/pihole-setup.sh`: delete the entire awk fallback block — the `# Fallback: if pihole-FTL --config...` comment plus the `if [[ -f /etc/pihole/pihole.toml ]]; then ... fi` block (currently lines 71-82)
5. [ ] Run `shellcheck -x scripts/pihole-setup.sh`, reach exit 0
6. [ ] Run `./validate.sh`, reach exit 0
7. [ ] Feature checks:
   - `grep -c 'awk' scripts/pihole-setup.sh` → `0`
   - `grep 'exit 1' scripts/pihole-setup.sh` → at least two lines (webserver.port and dns.upstreams)
   - `grep 'grep -q.*8080.*pihole.toml' scripts/pihole-setup.sh` → one matching line
