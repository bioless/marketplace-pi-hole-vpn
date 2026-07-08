---
name: critique
description: Evaluate whether a proposal represents the optimal solution given the actual codebase. If the problem is real but the approach is flawed, revise the proposal in place with a tracked Revision entry. Use before /plan when a proposal needs validation.
disable-model-invocation: true
argument-hint: [proposals/NNN-name.md | all]
---
Evaluate the proposal(s) at: $ARGUMENTS

Steps:

1. **Read the proposal, and confirm it is eligible.** Take in the full text: the problem, the
   why, and the rough approach. Only a proposal with `Status: proposed` and a blank Decision is
   eligible (a promoted, deferred, declined, or shipped proposal carries a human decision that
   `/critique` must not overwrite).
   - If the argument is `all`, process every eligible file in `proposals/` one at a time, and
     skip the rest.
   - If the argument is an explicit path, apply the same check: when that proposal already has a
     decision or a non-`proposed` Status, stop and report "already decided, skipping" rather than
     re-deciding it.

2. **Ground-truth the problem.** Read every source file the proposal touches or implies:
   - Use Grep to find every occurrence of the symptom (the hardcoded value, the wrong variable,
     the missing guard, the pattern in question).
   - Use Read to examine the relevant functions in full.
   - Use Glob to find files the proposal may have missed.
   The goal: confirm the problem actually exists in the current code and is not already fixed.

3. **Evaluate the proposed approach against three criteria:**

   A. **Correctness** (does the approach actually fix the root cause, or does it treat a symptom
      while the root persists elsewhere?) Does it miss callsites?

   B. **Completeness** (does the proposed scope cover every file and every path that exhibits
      the problem?) Does it over-specify, asking for changes not needed?

   C. **Optimality** (given the codebase's constraints, is this the simplest approach that fully
      resolves the problem?) The constraints to weigh: the invariants in CLAUDE.md (its "Read
      first: safety and intent" and "Do not" sections), the closed loop (the project's validation, per CLAUDE.md, must
      reach exit 0), and the project's existing structure and conventions. Is there a one-line fix
      where the proposal suggests a larger change?

4. **Verdict:** one of three outcomes.

   **OPTIMAL** (problem confirmed, approach correct, scope complete, no simpler path): write
   "OPTIMAL" with a one-paragraph justification and recommend `/plan proposals/NNN-name.md`.

   **DECLINE, no replacement** (the problem is already solved in the current code, or does not
   exist): fill in the Decision block, checking the decline box, and stop. Do not write a
   replacement, since there is no real problem left to solve. A replacement here would itself be
   already-solved and would loop on the next `/critique all` run.
   ```
   - [x] decline
   Notes: <one sentence: problem already solved / not present, no replacement needed>
   ```

   **REVISE in place** (the problem is real, but the approach is suboptimal: misdescribed,
   wrong scope, or a better path exists):
   a. Correct the approach directly in the proposal, editing only the sections that need it,
      grounded in what you found in step 2.
   b. Track the change: append the current date to the `Modified:` list and add an entry to
      `## Revisions` (newest last) summarizing the prior approach and why it changed. If the
      proposal predates these fields, add them first (adopt-on-touch), then append.
   c. Leave the Decision block untouched. The human still decides whether to promote.

5. **Report a verdict table** (one row per proposal evaluated):

   | Proposal | Verdict | Action |
   |----------|---------|--------|
   | 018-foo  | OPTIMAL | Ready for `/plan` |
   | 021-bar  | DECLINED (already solved) | Declined, no replacement |
   | 024-baz  | REVISED (approach corrected) | Revised in place; see its Revisions entry |

Do not write specs. Do not change source code. Do not implement anything. Every file you write
goes to `proposals/` only. Follow the writing style in CLAUDE.md.

Next: for OPTIMAL proposals, run `/clarify proposals/NNN-name.md` if the approach needs tightening,
or `/plan proposals/NNN-name.md` to promote directly. For REVISED proposals, review the corrected
approach and its Revisions entry, then `/clarify` or `/plan` when ready.
