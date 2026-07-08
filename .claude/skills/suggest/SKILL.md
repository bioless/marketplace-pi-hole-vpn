---
name: suggest
description: Surface an improvement opportunity as a reviewable proposal in proposals/. Use this on your own when you notice a worthwhile refactor, hardening, test gap, or feature, or when asked to brainstorm improvements. Writes a proposal only. Does not write specs and does not change code.
allowed-tools: Read, Write, Glob, Grep
---
Capture one improvement idea as a proposal for later human review.

Steps:
1. Read `proposals/TEMPLATE.md` and the existing files in `proposals/` to match the format and avoid duplicates.
2. Identify one concrete improvement: a refactor, a hardening, a test gap, a missing feature, or a self-improvement to this repo's workflow and tooling. One idea per proposal.
3. Pick the next number (highest existing NNN plus one) and a short kebab-case name.
4. Write `proposals/NNN-<name>.md` from the template. Set `Status: proposed`, stamp `Date`, and leave `Modified:` and `## Revisions` empty (they track later changes). Keep it lightweight: the problem, why it matters, a rough approach, rough effort, and any CLAUDE.md invariant it would touch. This is an idea, not an executable spec.
5. Follow the writing style in CLAUDE.md.

Do not write into `specs/`. Do not change code. Do not mark anything `ready`. Report the proposal path and a one-line summary. The human decides later whether to validate the approach with `/critique` and promote it to a spec with `/plan`.
