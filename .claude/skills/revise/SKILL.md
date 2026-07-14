---
name: revise
description: Surgically edit an existing spec or proposal with a tracked history entry, maintaining bidirectional references. Never promotes, never fills a Decision block, never touches code. Invoke explicitly with the document path and the change.
disable-model-invocation: true
argument-hint: [specs/NNN-name.md | proposals/NNN-name.md] [change]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(git log:*)
---
Revise the document at: $ARGUMENTS

Steps:

1. Locate the target from the argument. It must be a file under `specs/` or `proposals/`. Anything else, stop: `/revise` edits planning artifacts only.
2. Apply the guards. On a refusal, stop and say why:

   | Target | Allowed | Refused |
   | --- | --- | --- |
   | Proposal, undecided | Content edits plus a Revisions entry | Filling the Decision block |
   | Proposal, decided | Nothing | Any edit (history is closed; changes belong in the spec it became) |
   | Spec `draft` / `ready` / `in progress` | Content edits plus an Amendments entry | Flipping Status to `ready` (the human promotes via `/plan`) |
   | Spec `done` | Corrections: errors, wording, references, amendments | Scope-expanding edits (write a new spec that back-references this one instead) |

3. Scope the edit narrowly. Touch only the sections the request names.
4. Adopt-on-touch: if the target predates the living-document format and lacks the tracking sections, add them first. Backfill `Created` from `git log --follow --diff-filter=A --format=%as -- <file>` (the add-commit date, no pipeline needed), or "unknown" if git history is unavailable; the lists start from now.
5. Apply the edit, preserving structure and the writing style in CLAUDE.md.
6. Track it in the document itself: for a spec, append an entry to `## Amendments` (newest last, dated, with the why) and append to the metadata `Modified` and `Sessions` lists; for a proposal, append to `## Revisions` and `Modified`.
7. References: when the edit adds or changes a relationship to another spec or proposal, update `Back refs` / `Forward refs` on both documents so links stay bidirectional. If the counterpart file is missing, update this side and report the dangling reference instead of failing.
8. Report the edit, the tracked entry, and any refusal. Name the next step: `/tasks` if buildable scope changed, `/validate` otherwise.

Do not touch code. Do not promote, decide, or change any Status except appending metadata. A revision that changes what will be built sends the spec back through `/tasks` before `/implement`.

Next: `/tasks <spec>` if the change affects the build plan; otherwise the document is current and the loop continues wherever it was.
