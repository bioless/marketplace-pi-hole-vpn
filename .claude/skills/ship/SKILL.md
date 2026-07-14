---
name: ship
description: Validate, sync the docs to the change, then commit. Pushing stays a separate manual step by default. Invoke explicitly when ready to commit.
disable-model-invocation: true
argument-hint: [commit message]
allowed-tools: Bash(./validate.sh:*), Bash(./validate.ps1:*), Bash(pwsh:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git log:*), Read, Edit
---
Finalize the current work.

1. Run the project's validation (the command named in CLAUDE.md). If it does not exit 0, stop and report. Do not commit a failing tree.
2. Confirm no secret files are staged (the credential and sensitive-output patterns CLAUDE.md and `.gitignore` name). If any are present, stop and report.
3. Sync the docs to the change. Read the full diff (`git diff HEAD`), then update the docs so they match what shipped:
   - **README.md**: the parts the change affects (flags or commands table, build/run notes, the project-status list). Remove the TODO marker for any capability this change makes real.
   - **CLAUDE.md**: the Roadmap table, the "Specs ready to build now" list, and any architecture or module line whose behavior changed. When this change completes a roadmap row or a ready spec, move or drop that entry.
   - Any architecture or design doc the change affects.
   Edit only the sections the diff actually affects. If a file needs no change, say so and leave it untouched. Match the writing style in CLAUDE.md.
   Guardrails: do not weaken, reword, or remove the "Read first: safety and intent" section, the invariants it names, or the "Do not" list. These hold even when the diff touches nearby text.
4. Update the source proposals (if any). A single ship can complete more than one spec, so handle every shipped spec, not just one. This step is for shipped implementations only, not for committing the output of `/plan`.
   - From `git diff HEAD`, list each `specs/NNN-name.md` that this change marks `Status: done`: either a spec added already at `Status: done`, or an existing spec whose status line flips to `done`. Skip a spec added at `Status: ready` or `draft` (that is a freshly planned spec, nothing has shipped yet), so its proposal stays untouched.
   - For each shipped spec, read its header `Related:` line and pull out every `proposals/NNN-name.md` path it names. The line wording varies (`Related: proposal \`proposals/025-...md\``, `Related: proposals \`proposals/027-...md\` and \`proposals/028-...md\``, or a bare `Related: proposals/NNN-name.md`), so match the `proposals/NNN-name.md` path token wherever it appears, backticked or not, rather than a fixed prefix.
   - For each proposal path found, open that file and record the shipped spec in its `Status:` line. If the proposal is not yet shipped, set `Status: shipped → specs/NNN-name.md`. If it already reads `Status: shipped → ...`, append the new spec to that list rather than overwriting the earlier link. A spec whose `Related:` names only a roadmap item or research note, or no proposal path at all, has nothing to update; skip it.
5. Show me `git status --short` and a one-line-per-file summary of what will be committed, including the doc edits.
6. Stage the changes and create a commit with this message: $ARGUMENTS
   If no message was given, write a concise conventional-commit message derived from the diff.
7. After the commit exists, append its SHA to the `Commits` list of every spec this ship completed (adopt-on-touch if a spec predates the metadata block; edit only the metadata line, not any example block), and commit that update as a small follow-up bookkeeping commit. Do not amend: amending would change the SHA you just recorded. In a squash-merge PR flow the local SHA disappears at merge; update the list to the squash SHA afterward with `/revise` (a correction, allowed on done specs).

Markdown doc edits do not affect the build, so step 1's result still holds and no re-validation is needed.

Do not push. After committing, tell me the exact command to push when I am ready.

Optional (push and open a draft PR): if this project ships by pushing rather than stopping at the commit, say so in CLAUDE.md, then add `Bash(git push:*)` (and, to open a PR, your GitHub tool) to this skill's `allowed-tools`, and add a step 7: push `-u origin <branch>` and open a draft PR. Keep the conservative default above unless a project opts in.
