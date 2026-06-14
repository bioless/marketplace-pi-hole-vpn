---
name: validate
description: Run the closed-loop validation (shellcheck, terraform, secret scan) and drive it to exit 0. Use after making code changes to confirm the scripts and config are clean.
allowed-tools: Bash, Read, Edit
---
Run `./validate.sh` and report the result.

If it exits non-zero:
1. Read the FAIL line to identify the first failing check (shellcheck, terraform fmt, terraform validate, packer validate, or secret scan).
2. Diagnose the root cause from the output and the relevant source file.
3. Apply the smallest fix that addresses it. Honor the CLAUDE.md invariants (admin UI on wg0 only, no hardcoded secrets, shellcheck clean, Pi-hole v6 pihole.toml only, no lighttpd).
4. Re-run `./validate.sh`.
5. Repeat until it exits 0, or stop and report if the failure needs a decision from me.

Do not commit. Do not weaken or skip a check to make it pass.
