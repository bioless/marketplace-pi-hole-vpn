---
name: implement
description: Implement a reviewed spec and drive validation to exit 0. Invoke explicitly with the spec path.
disable-model-invocation: true
argument-hint: [specs/NNN-name.md]
---
Implement the spec at: $ARGUMENTS

Steps:
1. Read the spec in full, plus every file it lists under "Files to change".
2. Confirm the target is a real spec, not a proposal. If the path is under `proposals/` or its Status is `proposed`, stop. Tell me to promote it first with /plan, and do not implement it.
3. Confirm the spec Status is `ready`. If it is still `draft`, stop and ask before changing code.
4. If the spec has no populated Task checklist, suggest I run /tasks first, then proceed once tasks exist.
5. Make the changes the spec describes. Honor the CLAUDE.md invariants: admin UI on wg0 only, no hardcoded secrets (keys and passwords generated at runtime), shellcheck clean, Pi-hole v6 pihole.toml only (no lighttpd, no setupVars.conf runtime config), WireGuard PSK for all peers.
6. Run `./validate.sh` and drive it to exit 0, fixing your own changes as needed. Do not weaken a check to make it pass.
7. Run the spec's feature-specific validation checks.
8. Update README.md if behavior changed and remove the matching TODO note.
9. Set the spec Status to `done`.

Do not add an external package dependency unless the spec records that decision and its tradeoff. Do not commit. Report what changed, the validation result, and anything that needs my decision.

Next: run /review to check the diff, then /ship "message" to commit.
