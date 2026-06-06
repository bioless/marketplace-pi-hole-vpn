# Spec: <feature name>

Status: draft | ready | in progress | done
Owner: <you>
Related: <proposal or roadmap item>

## Context

What exists today and why this change is needed. Two or three sentences. Link the relevant script or config file.

## Goal

One sentence. The single outcome this spec delivers.

## Scope

In scope:
- <bullet>

Out of scope (do not build):
- <bullet>

## Design

How it works. Cover the data flow and the key decision. Note any invariant from CLAUDE.md that this must not break (admin UI on wg0 only, no hardcoded secrets, shellcheck clean, Pi-hole v6 pihole.toml only, no lighttpd, WireGuard PSK for all peers).

## Files to change

| File | Change |
| --- | --- |
| `scripts/example.sh` | what changes |

New files:
- `scripts/new-script.sh` : purpose

## Validation

The change is done when `./validate.sh` exits 0 AND the checks below pass.

Feature-specific checks:
- [ ] <concrete, observable check with the exact command and expected output>

## Failure modes to handle

- <condition> : <required behavior>

## Acceptance criteria

- [ ] <testable statement>
- [ ] `shellcheck -x scripts/*.sh` passes
- [ ] `./validate.sh` exits 0
- [ ] No new external package dependency added (or: dependency decision recorded here)

## Task checklist

1. [ ] <step>
2. [ ] <step>
3. [ ] Run `./validate.sh`, reach exit 0
4. [ ] Update README.md if behavior or user-facing workflow changed
