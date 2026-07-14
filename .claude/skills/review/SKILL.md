---
name: review
description: Review pending changes (uncommitted, or unpushed commits when the tree is clean) against repo standards, triage findings by severity and scope, and capture out-of-scope findings to proposals/. Use before committing or pushing.
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Write
---
Review the current pending changes. You may write to `proposals/` to capture findings. You must NOT edit code, specs, CLAUDE.md, skills, or anything outside `proposals/`.

1. Determine the review surface and read it:
   - Run `git status --short`. If there are uncommitted changes, review them with `git diff` (plus staged with `git diff --cached`).
   - If the tree is clean, review the unpushed commits instead: `git log @{u}.. --stat` and `git diff @{u}..`.
2. Check against:
   - The invariants in CLAUDE.md (its "Read first: safety and intent" and "Do not" sections).
   - No committed secrets: no credential or sensitive-output files staged (the patterns CLAUDE.md and `.gitignore` name).
   - Conventions in CLAUDE.md: the format and lint checks clean, errors handled with context, the writing style (active voice, the project's prose rules). A new entry in a dependency manifest is a finding unless the change records the decision.
   - Correctness and obvious failure modes for the changed code.
3. For each finding, tag two things:
   - Severity: blocker, should-fix, or nit.
   - Scope: introduced by this change, or pre-existing/adjacent. The test: did this change introduce the finding, or did it merely sit near it?
4. Sort findings into three buckets:
   - **Must fix before ship**: every blocker, plus should-fix items introduced by this change.
   - **Fix if quick**: one-line nits on files this change already touches.
   - **Backlog**: should-fix or nits that are pre-existing or out of scope.
5. Capture every finding except the must-fix list, so nothing is lost. `/review` does not edit code, so even a fix-if-quick nit is only addressed if a later step acts on the report; file it rather than trust that. For each distinct should-fix (fix-if-quick or backlog), write a `proposals/NNN-<name>.md` from `proposals/TEMPLATE.md` with `Status: proposed`, `Author: agent`, and a note in the Problem section that it came from a review finding. Group every nit (fix-if-quick and backlog) into a single `proposals/NNN-review-nits.md` rather than one file each. Do not duplicate a proposal that already exists. Do not file the must-fix items; they block the ship and get fixed before it.
6. Report a findings ledger so nothing can silently drop: a table of every finding with its severity, scope, bucket, and disposition (on the must-fix list, captured into a named `proposals/` file, or fixed). Every finding must show a disposition. List the must-fix items explicitly, and name the proposal files you created.

End with one verdict: **safe to ship once the must-fix list is clear**, or **changes needed** with the must-fix list.

Next: fix the must-fix items and re-run /validate, then /ship. Every other finding is already captured in proposals/ for later triage.
