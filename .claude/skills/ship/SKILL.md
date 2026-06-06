---
name: ship
description: Validate, sync README + CLAUDE.md to the change, then commit. Pushing stays a separate manual step. Invoke explicitly when ready to commit.
disable-model-invocation: true
argument-hint: [commit message]
allowed-tools: Bash(./validate.sh:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git commit:*), Read, Edit
---
Finalize the current work.

1. Run `./validate.sh`. If it does not exit 0, stop and report. Do not commit a failing tree.
2. Confirm no secret files are staged: no `*.key`, `*.pem`, `*.p12`, `.pihole-admin-pass`, or `wg0.conf`. If any are present, stop and report.
3. Sync the docs to the change. Read the full diff (`git diff HEAD`), then update files so they match what shipped:
   - **README.md**: flags, scripts table, and client setup sections. Remove the TODO marker for any capability this change makes real.
   - **CLAUDE.md**: the Roadmap table, the "Specs ready to build now" list, and any architecture or convention line whose behavior changed. When this change completes a roadmap row or a ready spec, move or drop that entry.
   Edit only the sections the diff actually affects. If a file needs no change, say so and leave it untouched. Match the repo writing style: no em dashes, never the word "ensure," active voice.
   Guardrails: do not weaken, reword, or remove the "Read first: safety and intent" section, the admin UI wg0 binding, the no-hardcoded-secrets notes, or the "Do not" list. These hold even when the diff touches nearby text.
4. Show me `git status --short` and a one-line-per-file summary of what will be committed, including the doc edits.
5. Stage the changes and create a commit with this message: $ARGUMENTS
   If no message was given, write a concise conventional-commit message derived from the diff.

Markdown doc edits do not affect the build, so step 1's result still holds and no re-validation is needed.

Do not push. After committing, tell me the exact command to push when I am ready.
