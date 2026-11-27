---
name: dsh-worker
description: Delegate a coding task to the DeepSeek worker (dsh CLI, DeepSeek-V4.1-Flash) as small step-by-step task cards at low/medium effort, then review and commit. Use for any code change in FinalRun.
---

# dsh-worker

The supervisor does the thinking; the worker types. Design, ordering, names, signatures, and edge cases are decided in the card. The worker follows the steps and does not redesign. Small cards at medium effort finish in minutes; one big brief at max effort spends most of its time reasoning.

## 1. Design and brief (once per feature)
- Design doc (`docs/design/*.md`) and feature brief (`docs/BRIEF_<topic>.md`) hold the decisions. EGM-review them per `CLAUDE.md`.
- The brief is the supervisor's reference. Do not hand the whole brief to the worker.

## 2. Cut task cards
Split the brief into cards: `docs/tasks/<topic>/NN-<slug>.md`, one concern each, about 1-4 files and under ~150 lines of new code. Order them so each card builds on committed work.

Card template (English):

```markdown
# <topic> NN: <one-line goal>

## Files
- create: `features/downed/DownedService.gd`
- modify: `lib/constants/GameConst.gd`

## Steps
1. In `lib/constants/GameConst.gd`, add `const BLEED_OUT_MS := 60000` under `# Downed`.
2. In `features/downed/DownedService.gd`, create `class_name DownedService extends RefCounted` with
   `func can_revive(reviver_life: int, target_life: int, same_party: bool, same_role: bool) -> bool`:
   true only when reviver_life == ALIVE, target_life == DOWNED, same_party, same_role.
3. ...

## Reuse
- `NetUtil.rpc_members(...)` for sending, `ItemUtils.find_by_uid(...)`.

## Do not
- Do not touch files outside the list. Do not rename existing functions. Do not run git.

## Tests
- `tests/features/downed/test_downed_service.gd`: `test_can_revive_requires_same_party` asserts ...
- Register the test file in `tests/run_tests.gd`.

## Done when
- `godot_console --headless --path . --import` has no script errors.
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, last 5 lines of the test output, any step you could not do and why.
```

Rules for steps:
- Exact paths, exact names, exact signatures and types, constant names and values, signal and RPC names with their annotations.
- Behavior as plain conditions ("true only when ..."), not "handle X properly".
- Copy the relevant rule from `docs/CONVENTIONS.md` or `docs/ARCHITECTURE.md` into the step instead of telling the worker to read the whole doc.
- Pseudo-code is fine for tricky order (death sequence, RPC flow). Full implementations are the worker's job.
- No open questions. If something is undecided, decide it first.

## 3. Run the card
Effort by card:
- `dsh-flash-medium.yml`: default for a card.
- `dsh-flash-low.yml`: mechanical edits (rename, add constants, register tests, move files).
- `dsh-flash-high.yml`: the card failed once.
- `dsh-flash-max.yml`: failed twice, or a networking race / sync bug that the card cannot fully spell out.

Run in background from the repo root (PowerShell):

```powershell
"Read docs/tasks/<topic>/NN-<slug>.md. Do exactly its steps, in order, nothing more. Do not redesign. If a step cannot be done as written, stop and say why. Run the Done-when commands. Do not run git." |
  dsh --profile headless --patch .claude/skills/dsh-worker/dsh-flash-medium.yml `
      --permission-mode workspace-write --approval-policy never - *> logs/dsh-<topic>-NN.log
```

- While card NN runs, write card NN+1. Run two cards at once only when their file lists do not overlap.
- `logs/` is gitignored.
- `MISSING_CREDENTIAL` or `ACCOUNT_SIGN_IN_REQUIRED`: the user must sign in through the DeepSeek Harness desktop app.

## 4. Review
- `rtk git status`, then plain `git diff` (never filtered). Check every step of the card was done and nothing outside the file list changed.
- Run the checks in `CLAUDE.md` yourself.
- Check `docs/CONVENTIONS.md`: right folder, `lib/` has no feature imports, no magic numbers, no raw `rpc()` broadcast.
- Problem: write a fix card `NNb-fix-<slug>.md` with the failing output pasted in, one effort level up. Do not hand-edit code.
- Append new gotchas to `AGENTS.md` → "Lessons learned".

## 5. Commit
One commit per card (or per concern), Conventional Commits, explicit paths, no co-author line. Commit the card file with it.
