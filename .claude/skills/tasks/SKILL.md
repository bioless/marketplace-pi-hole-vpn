---
name: tasks
description: Break a build-ready spec into an ordered, dependency-aware task checklist with parallel markers. Invoke with a spec path.
disable-model-invocation: true
argument-hint: [specs/NNN-name.md]
allowed-tools: Read, Write, Glob
---
Generate the task breakdown for the spec at: $ARGUMENTS

Steps:
1. Read the spec in full, including its Design and Files to change sections.
2. Confirm it is a real spec under `specs/`, not a proposal. If the path is under `proposals/` or its Status is `proposed`, stop and tell me to run /plan first.
3. Produce an ordered task list and write it into the spec's "## Task checklist" section, replacing the placeholder. Each task must:
   - State the action and the exact file path it touches.
   - Be ordered so dependencies come first (firewall rules before services that depend on them, config files before the service that reads them).
   - Carry a `[P]` marker when it can run in parallel with the adjacent task (no shared file, no dependency between them).
   - Place any validation or test change before the code it checks, where that fits.
4. End the list with: run `./validate.sh` to exit 0, then the spec's feature-specific checks.

Keep tasks small and concrete. Do not implement anything here.

Next: run /implement <spec> to build it.
