# Spec: <feature name>

Status: draft | ready | in progress | done
Owner: <you>
Related: <proposal / roadmap item>
Created: <YYYY-MM-DD>
Modified:
Commits:
Sessions:
Back refs:
Forward refs:

<!-- Lifecycle metadata. Every field below Created is an append-only comma-separated
     list: /plan stamps Created and seeds Back refs, /implement appends Modified and
     Sessions, /ship appends Commits, /revise maintains the refs. Never overwrite or
     remove an existing entry. -->

## Context

What exists today and why this change is needed. Two or three sentences. Link the relevant module or file.

## Goal

One sentence. The single outcome this spec delivers.

## Scope

In scope:
- <bullet>

Out of scope (do not build):
- <bullet>

## Design

How it works. Cover the data flow and the key decision. Note any invariant from CLAUDE.md this must not break (its "Read first: safety and intent" and "Do not" sections).

## Files to change

| File | Change |
| --- | --- |
| `path/to/file` | what changes |

New files:
- `path/to/new` : purpose

## Validation

The change is done when the project's validation (per CLAUDE.md) exits 0 AND the checks below pass.

Feature-specific checks:
- [ ] <concrete, observable check with the exact command and expected output>

## Failure modes to handle

- <condition> : <required behavior>

## Acceptance criteria

- [ ] <testable statement>
- [ ] The project's validation (per CLAUDE.md) exits 0
- [ ] No new external dependency added (or: dependency decision recorded here)

## Task checklist

Markers: `[ ]` idle, trailing `wip` in progress, `[x]` complete, trailing `failed: reason` blocked. The build agent updates markers in place as it works, so this list is the live progress tracker.

<!-- For work with 2 or more natural stages or roughly 8 or more tasks, group the
     steps into "### Phase N: <name>" sections. Each phase ends with a validation
     gate: "Phase gate: <check>. Do not start the next phase until this passes."
     Smaller work keeps the flat list below. -->

1. [ ] <step>
2. [ ] <step>
3. [ ] Run the project's validation (per CLAUDE.md), reach exit 0
4. [ ] Update README/docs if behavior changed

## Amendments

<!-- Append-only history of changes made after this spec was first built, newest
     last, one dated line each: "- YYYY-MM-DD: what changed and why". Written by
     /revise. Leave empty at authoring time. -->
