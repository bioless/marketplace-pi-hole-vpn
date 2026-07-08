---
name: pr-review
description: Monitor an open pull request, triage and address returned reviewer comments (bots or humans), reply, re-validate, and hand the merge back to you. Opt-in for repos that ship via GitHub PRs; needs the gh CLI.
disable-model-invocation: true
argument-hint: [PR number | branch]
---
Run the PR review cycle for: $ARGUMENTS (default: the PR for the current branch).

This skill is for projects that ship through GitHub pull requests. It needs the `gh` CLI and a PR to exist. If `gh` is missing or there is no PR for the branch, say so and stop. Read CLAUDE.md for the project specifics: which reviewers to request, how many re-review rounds to allow, and whether merging is hand-off (the default) or automated.

Steps:

1. **Find the PR.** Use `gh pr view` for the current branch (or the given number). If there is no PR, stop and report. If the PR's head branch is not the one checked out, check it out first (or stop), so the later fixes, commit, and push act on the PR's branch and not whatever is currently checked out. Note the head commit SHA.

2. **Request review** per CLAUDE.md (for example a Copilot reviewer, or a `@codex review` comment). Skip any reviewer the project does not use. If CLAUDE.md configures no reviewer at all, do not let step 6 pass vacuously: stop and ask which reviewer to use, unless CLAUDE.md explicitly opts into proceeding without review.

3. **Wait for reviews.** Poll for submitted reviews and unresolved inline comments across the PR, not only on the current head commit, so a review of an earlier commit that was in flight when you pushed a fix is not missed. Match the review-author login (for example `copilot-pull-request-reviewer[bot]` or `chatgpt-codex-connector[bot]`), not the requested-reviewer display name, or the wait never resolves. Some bots react without leaving a review object when they find nothing, and some have usage limits; treat a clean signal or a stated limit as "no findings." Bound each wait with a per-round deadline (configurable in CLAUDE.md, default about 10 minutes); if it expires, note which reviewer did not respond and go to step 6 rather than wait forever.

4. **Triage each returned comment** by the scope test from `/review`: did this change introduce the issue, or did it merely sit near it?
   - Must-fix, or a should-fix introduced by this change: fix it.
   - Pre-existing or out of scope: capture it to `proposals/` instead.
   Reply on each thread with the disposition. Reply immediately for an item you file to `proposals/`; for a code fix, post the `fixed in <sha>` reply only after the commit exists (step 5), since the SHA does not exist yet here.

5. **Re-validate and re-review.** If this round produced any change (a code fix or a new `proposals/` capture), drive the project's validation (per CLAUDE.md) to exit 0, commit it (then post the deferred `fixed in <sha>` replies for code fixes), push, and re-request review. Commit proposal-only captures too, so a hand-off never leaves them uncommitted. (A bare `push` with nothing committed is a no-op, so the commit is what updates the PR head and gives you the SHA to cite.) Repeat from step 3 up to the round limit in CLAUDE.md (default 3). Stop early when a round returns no new findings.

6. **Hand off.** Re-poll once for any in-flight review (a fresh push can trigger a new one). If at least one reviewer actually reviewed, every requested reviewer responded, and no findings remain, report the clean state and print the merge command. If a reviewer timed out or the round limit was reached with findings still open, do not call it clean: list the non-responding or outstanding reviewers, mark the state incomplete, and do not offer to merge. Merge only if CLAUDE.md opts into automated merge, and never on a stale or incomplete review.

Do not weaken the project's validation to make a review pass. Do not merge without an explicit opt-in or the human's go-ahead.

Next: once merged, the change is shipped. Run `/suggest` to capture any follow-ups the review surfaced.
