---
name: validate
description: Run the closed-loop validation and drive it to exit 0. Use after making code changes to confirm the project still builds and passes its checks.
allowed-tools: Bash, Read, Edit
---
Run the project's validation (the command named in CLAUDE.md, for example `./validate.sh` on Unix/macOS or `.\validate.ps1` on Windows) and report the result.

If it exits non-zero:
1. Read the FAIL line to identify the first failing check (the checks are named in CLAUDE.md's "Validation: the closed loop" section).
2. Diagnose the root cause from the output and the relevant source file.
3. Apply the smallest fix that addresses it. Honor the invariants in CLAUDE.md (its "Read first: safety and intent" and "Do not" sections).
4. Re-run the project's validation.
5. Repeat until it exits 0, or stop and report if the failure needs a decision from me.

Do not commit. Do not weaken or skip a check to make it pass.
