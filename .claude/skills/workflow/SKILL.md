---
name: workflow
description: Show the Pi-hole VPN development workflow, what each skill does, and the order to run them. Invoke when unsure what to do next.
disable-model-invocation: true
---
Print this workflow map for the user, then stop. Take no other action.

# Pi-hole VPN workflow

Idea to shipped change, in order. Skills marked (auto) may run on their own. The rest you invoke with `/name`.

1. `/suggest`            (auto)  Agent writes improvement ideas to `proposals/`. Not build-ready.
2. `/critique <proposal | all>`  Evaluate proposals: confirm the approach is optimal, revise it in place with a tracked Revisions entry, or decline it. Run before clarifying to avoid investing in a wrong approach.
3. `/clarify <target>`           Ask focused questions to tighten a proposal, spec, or idea.
4. `/plan <desc | proposal>`     Author a build-ready spec in `specs/NNN-name.md`.
5. `/tasks <spec>`               Break the spec into an ordered task list with parallel markers.
6. `/implement <spec>`           Build the spec, drive the project's validation to exit 0.
7. `/validate`           (auto)  Closed loop: the project's single source of truth for "is this working."
8. `/review`             (auto)  Review changes, triage findings, capture backlog to `proposals/`. Never edits code.
9. `/ship "message"`             Validate, sync docs, then commit.

Any time:
- `/revise <spec | proposal>`    Surgical tracked edit to an existing spec or proposal; updates its history and references. Never promotes or decides.

Optional, for repos that ship via GitHub PRs:
- `/pr-review`           Monitor the PR, address returned reviewer comments, re-validate, then hand back the merge. Needs `gh`.

Optional, presentation:
- `/render <spec>`       Render a spec to a self-contained HTML page with diagrams (SVG by default). Output is derived and gitignored.

Typical path: `critique` then `clarify` then `plan` then `tasks` then `implement` then `review` then `ship`. `suggest` is the auto step that fills `proposals/`; you can run it any time.

Proposals path: `suggest` fills `proposals/`, `critique` validates the approach, then `clarify` or `plan` to promote one.

Two trust levels keep the loop honest:
- `proposals/`: candidate ideas (`Status: proposed`). Never implemented directly.
- `specs/`: decided, build-ready work (`Status: ready`). What `/implement` builds.

When stuck: run `/validate` to check the tree is healthy, or `/review` to see what changed.
