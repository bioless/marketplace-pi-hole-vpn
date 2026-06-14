---
name: clarify
description: Ask focused, structured questions to tighten a rough idea, proposal, or draft spec before planning. Invoke with a proposal path, a spec path, or a description.
disable-model-invocation: true
argument-hint: [proposals/NNN.md | specs/NNN.md | description]
---
Clarify the requirements for: $ARGUMENTS

Steps:
1. Read the target if it is a file (a proposal or a spec). If it is a freeform description, work from that.
2. Identify the underspecified areas: scope boundaries, edge cases, failure modes, success and acceptance criteria, and any CLAUDE.md invariant the work might touch (admin UI on wg0 only, no hardcoded secrets, shellcheck clean, Pi-hole v6 pihole.toml only, no lighttpd).
3. Ask a short, ordered set of questions, one topic at a time, highest impact first. Keep it focused. Do not ask about things already answered.
4. Record the answers. If the target is a spec file, add or update a "## Clarifications" section with the questions and answers. If it is a proposal or a description, summarize the resolved decisions so they can feed the spec.

Do not write code. Do not author a full spec here.

Next: run /plan (if you were clarifying an idea or proposal) or /tasks (if you were tightening an existing spec).
