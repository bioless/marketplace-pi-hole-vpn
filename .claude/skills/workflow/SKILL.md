---
name: workflow
description: Show the Pi-hole VPN development workflow, what each skill does, and the order to run them. Invoke when unsure what to do next.
disable-model-invocation: true
---
Print this workflow map for the user, then stop. Take no other action.

# Pi-hole VPN workflow

Idea to shipped change, in order. Skills marked (auto) may run on their own. The rest you invoke with `/name`.

1. `/suggest`            (auto)  Agent writes improvement ideas to `proposals/`. Not build-ready.
2. `/clarify <target>`           Ask focused questions to tighten a proposal, spec, or idea.
3. `/plan <desc | proposal>`     Author a build-ready spec in `specs/NNN-name.md`.
4. `/tasks <spec>`               Break the spec into an ordered task list with parallel markers.
5. `/implement <spec>`           Build the spec, drive `./validate.sh` to exit 0.
6. `/validate`           (auto)  Closed loop: shellcheck, terraform, secret scan.
7. `/review`             (auto)  Review changes, triage findings, capture backlog to `proposals/`. Never edits code.
8. `/ship "message"`             Validate, sync README + CLAUDE.md, then commit. Push stays a manual step.

Typical path: `clarify` then `plan` then `tasks` then `implement` then `review` then `ship`.

Proposals path: `suggest` fills `proposals/`, you triage, then `clarify` or `plan` to promote one.

When stuck: run `/validate` to check the tree is healthy, or `/review` to see what changed.
