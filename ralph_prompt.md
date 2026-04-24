# Ralph Loop Prompt

Paste this as the prompt to the coding agent at the start of **every** iteration. It is deliberately the same every time — the agent orients from `spec.md` and `PROGRESS.md`, not from the prompt.

---

## The prompt

```
You are working on the Pushup Tracker iOS app in a Ralph loop.

Your first two actions, always, before anything else:

1. Read `spec.md` in full.
2. Read `PROGRESS.md` in full.

These two files are the source of truth for what this project is, what has been
done, and what to do next. Trust them over your own assumptions.

Then do exactly one iteration of work, following this protocol:

STEP 1 — ORIENT
- Identify the current milestone from PROGRESS.md.
- If there are entries under "Blockers", STOP. Do nothing else. Update
  "Last iteration notes" to say you stopped due to blockers and exit.
- Otherwise, pick the SMALLEST next unit of work in the current milestone.
  Small means: one focused change, typically 1–3 files, completable and
  testable in one pass.

STEP 2 — CHECK LOCKED DECISIONS
- Review §2 (Locked Decisions) and §13 (Invariants) in spec.md.
- If the work you're about to do conflicts with either, STOP. Add the
  conflict to "Open questions" in PROGRESS.md and pick a different unit
  of work. Do not silently deviate.

STEP 3 — EXECUTE
- Make the change.
- Stay within the current milestone's scope. If you notice cleanup or
  improvements outside that scope, DO NOT do them. Note them under
  "Open questions" if they seem important.
- Do not rewrite code from earlier milestones unless you are fixing a
  real bug, and if so, note it.

STEP 4 — TEST
- Run `swift test --package-path PushupCore` for package changes.
- Run the full xcodebuild test command from §10 when app/widget code
  changes.
- If tests fail: fix them before continuing. Do not mark the iteration
  complete with failing tests.
- If a test failure reveals something that can't be fixed in this
  iteration, add it to "Blockers" and stop.

STEP 5 — UPDATE PROGRESS.md
- Update "Last iteration notes" with what you actually did, in past
  tense. Facts only, no plans. Include surprises, dead ends, things
  that took longer than expected.
- If the current milestone's exit criteria are now all met:
  - Move the milestone from "Current milestone" to "Completed" with
    the commit SHA.
  - Promote the next milestone from "Remaining" to "Current milestone"
    and fill in its goal and exit criteria (reference spec.md §11).
- If you encountered questions that don't block progress, add them to
  "Open questions".
- If you encountered something that DOES block progress, add it to
  "Blockers".

STEP 6 — COMMIT
- Stage all changes.
- Commit with message: `M<n>: <brief description of what this iteration did>`
- Example: `M1: add PushupCore package with placeholder test`

STEP 7 — STOP
- Output a one-paragraph summary of the iteration.
- Do not start another iteration. The loop driver will invoke you again.

RULES
- Never modify spec.md. If the spec is wrong, add an entry to
  "Open questions" in PROGRESS.md.
- Never add third-party dependencies.
- Never touch anything in the out-of-scope list (spec.md §3).
- Never invent answers to ambiguous questions — write them down and
  move on or stop.
- One iteration = one commit. If you find yourself wanting to make two
  unrelated commits, you're doing too much; split across iterations.
- If you've written more than ~200 lines of code in this iteration,
  you're probably doing too much. Wrap up, commit, stop.
```

---

## Operator notes (not part of the prompt)

**Before the first iteration**, make sure the repo has:
- `spec.md` at repo root
- `PROGRESS.md` at repo root
- `.git` initialized with at least an initial commit
- Xcode + simulator installed, signed into your Apple Developer account

**Running the loop.** Two common shapes:

1. **Manual** — run the prompt, review the commit, run it again. Slower but highest oversight. Recommended for the first 3–4 iterations so you can correct course if the agent is misreading the spec.

2. **Automated** — a shell loop that keeps invoking the agent until `PROGRESS.md` shows all milestones complete OR a blocker is present. Minimal sketch:

   ```bash
   while true; do
     claude --prompt "$(cat ralph_prompt.md)"
     if grep -q "^\*\*M10.*complete" PROGRESS.md; then break; fi
     if grep -q "^## Blockers" PROGRESS.md && \
        ! grep -q "^## Blockers\n_(empty)_" PROGRESS.md; then
       echo "Blocker detected. Stopping."
       break
     fi
     sleep 2
   done
   ```

   (Tune the done/blocker detection to your actual grep patterns; the above is illustrative.)

**When the loop goes sideways.** Symptoms and fixes:

- *Agent keeps "improving" earlier code.* The anti-drift invariants aren't being respected. Read the last few commits; if the agent is touching M2 files during M5, tighten §14 of spec.md with specific examples.
- *Agent invents answers.* Usually means the spec is ambiguous in a specific place. Find where, tighten it.
- *Agent marks milestones complete prematurely.* The exit criteria in PROGRESS.md aren't concrete enough. Make them checkbox-level specific (they already are for M1 — keep that pattern).
- *PROGRESS.md grows unwieldy.* Every 3–4 milestones, archive old "Last iteration notes" entries into a `PROGRESS_ARCHIVE.md`. Keep the active file tight.

**First iteration expectations.** M1 alone is probably 2–4 iterations: scaffold the Xcode project, add the package, add the widget target, wire up App Group entitlements, verify. That's normal — resist the urge to collapse it into one.