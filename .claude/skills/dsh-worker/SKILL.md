---
name: dsh-worker
description: Delegate a coding task to the DeepSeek worker (dsh CLI, DeepSeek-V4.1-Flash, effort high by default, max for hard tasks), then review and commit. Use for any code change in FinalRun.
---

# dsh-worker

## 1. Write the brief
Put the task in `docs/BRIEF_<topic>.md` (English). Include: goal, exact file paths (following `docs/CONVENTIONS.md`), hard constraints, which `lib/` helpers to reuse or create, and the verification commands the worker must run. Commit it: `docs(brief): add <topic> brief`.

## 2. Run the worker
Pick the patch file:
- `dsh-flash-high.yml` (default): brief is detailed, task is implementation.
- `dsh-flash-max.yml`: task failed twice on high, or hard problem (net race conditions, sync bugs, big refactor).

Run in background from the repo root (PowerShell):

```powershell
"Read docs/CONVENTIONS.md first and follow it strictly. Then read docs/BRIEF_<topic>.md and implement everything in it exactly. Run the verification commands and fix until they pass. Do not run git." |
  dsh --profile headless --patch .claude/skills/dsh-worker/dsh-flash-high.yml `
      --permission-mode workspace-write --approval-policy never - *> logs/dsh-<topic>.log
```

- `logs/` is gitignored. High/max effort reasons before writing files; a growing log with no new files is normal.
- Follow-up in the same session: `--session-id <id>` (id is in the log / `~/.dsh/sessions`).
- `MISSING_CREDENTIAL` or `ACCOUNT_SIGN_IN_REQUIRED`: the user must sign in through the DeepSeek Harness desktop app.

## 3. Review
- Read the diff (`git status`, `git diff`). Check the brief's constraints, not only that tests pass.
- Check `docs/CONVENTIONS.md`: files in the right folder, `lib/` has no feature imports, no duplicated logic, no magic numbers, no raw `rpc()` broadcast.
- Run the checks listed in `CLAUDE.md` yourself.
- Problems: write a short fix brief (or continue the session) and run the worker again. Do not hand-edit code.

## 4. Commit
Split by concern, Conventional Commits, explicit paths, no co-author line:
`feat(server): ...`, `feat(player): ...`, `refactor(lib): ...`, `test(core): ...`, `docs(architecture): ...`.
