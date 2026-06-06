---
name: plan
description: Draft a build-ready spec from specs/TEMPLATE.md, ready for review. Invoke explicitly when starting a new feature, or pass a proposals/ path to promote a proposal into a spec.
disable-model-invocation: true
argument-hint: [feature description | proposals/NNN-name.md]
allowed-tools: Read, Write, Glob
---
Create a new feature spec for: $ARGUMENTS

If the argument is a path under `proposals/`, this is a promotion: read that proposal first and base the spec on it. Set the proposal's Decision to "promote to spec" and reference the proposal path in the new spec's Context.

Steps:
1. Read `specs/TEMPLATE.md` and the existing specs in `specs/` to match the format and depth.
2. Pick the next spec number (highest existing NNN plus one) and a short kebab-case name.
3. Write `specs/NNN-<name>.md`, filling every section: context, goal, scope and non-goals, design, files to change, validation, failure modes, acceptance criteria, and a task checklist placeholder. The validation section must end in `./validate.sh` exit 0 plus at least one concrete feature-specific check with the exact command and expected output.
4. Name any CLAUDE.md invariant the work must not break (admin UI on wg0 only, no hardcoded secrets, shellcheck clean, Pi-hole v6 pihole.toml only, no lighttpd, WireGuard PSK for all peers).
5. Follow the repo writing style: no em dashes, never the word "ensure", active voice, tables over long prose.

Stop after writing the spec. Do not implement it. Report the file path and a one-paragraph summary for review.

Next: run /clarify <spec> if anything is fuzzy, then /tasks <spec> to break it into steps.
