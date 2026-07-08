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
5. Make the changes the spec describes, working the Task checklist in order and updating its markers in place (the spec is the live progress tracker): add a trailing `wip` (inline code) when starting a task, flip to `[x]` on completion, or record `failed: reason` and continue only if the phase allows. At each phase gate, run the named validation and do not start the next phase until it passes. Honor the invariants in CLAUDE.md (its "Read first: safety and intent" and "Do not" sections). If the spec predates the marker or metadata format, add the missing pieces first (adopt-on-touch).
6. Run the project's validation (the command named in CLAUDE.md) and drive it to exit 0, fixing your own changes as needed. Do not weaken a check to make it pass.
7. Run the spec's feature-specific validation checks.
8. Update the docs CLAUDE.md names (README and any architecture or design docs) if behavior changed, and remove the matching TODO note.
9. Set the spec Status to `done`, and append the current date to its `Modified` list and this agent/session to its `Sessions` list.

Do not add an external dependency unless the spec records that decision and its tradeoff. Do not commit. Report what changed, the validation result, and anything that needs my decision.

Next: run /review to check the diff, then /ship "message" to commit.
