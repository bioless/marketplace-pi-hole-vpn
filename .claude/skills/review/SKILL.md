---
name: review
description: Review uncommitted changes against repo standards, triage findings by severity and scope, and capture out-of-scope findings to proposals/. Use before committing, or when asked to review pending changes.
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Write
---
Review the current uncommitted changes. You may write to `proposals/` to capture findings. You must NOT edit code, specs, CLAUDE.md, skills, or anything outside `proposals/`.

1. Run `git diff` and `git status --short` to see what changed.
2. Check against:
   - CLAUDE.md invariants: admin UI on wg0 only (not 0.0.0.0), no hardcoded WireGuard keys or admin passwords, shellcheck-clean scripts, Pi-hole v6 pihole.toml only (no lighttpd, no setupVars.conf runtime config), WireGuard PSK for all peers.
   - Conventions: shellcheck clean, no hardcoded secrets, writing style (no em dashes, no "ensure", active voice).
   - Correctness and obvious failure modes for the changed scripts and config.
3. For each finding, tag two things:
   - Severity: blocker, should-fix, or nit.
   - Scope: introduced by this change, or pre-existing/adjacent. The test: did this change introduce the finding, or did it merely sit near it?
4. Sort findings into three buckets:
   - **Must fix before ship**: every blocker, plus should-fix items introduced by this change.
   - **Fix if quick**: one-line nits on files this change already touches.
   - **Backlog**: should-fix or nits that are pre-existing or out of scope.
5. Capture every finding except the must-fix list, so nothing is lost. For each distinct should-fix (fix-if-quick or backlog), write a `proposals/NNN-<name>.md` from `proposals/TEMPLATE.md` with `Status: proposed`, `Author: agent`, and a note in the Problem section that it came from a review finding. Group every nit into a single `proposals/NNN-review-nits.md` rather than one file each. Do not duplicate a proposal that already exists. Do not file the must-fix items; they block the ship and get fixed before it.
6. Report a findings ledger so nothing can silently drop: a table of every finding with its severity, scope, bucket, and disposition (on the must-fix list, captured into a named `proposals/` file, or fixed). Every finding must show a disposition. List the must-fix items explicitly, and name the proposal files you created.

End with one verdict: **safe to ship once the must-fix list is clear**, or **changes needed** with the must-fix list.

Next: fix the must-fix items and re-run /validate, then /ship. Every other finding is already captured in proposals/ for later triage.
