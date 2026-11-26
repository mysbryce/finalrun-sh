---
name: dsh-worker
description: Delegate a coding task to the DeepSeek worker (dsh CLI, DeepSeek-V4.1-Flash, reasoning effort max), then review and commit. Use for any code change in FinalRun.
---

# dsh-worker

## 1. Write the brief
Put the task in `docs/BRIEF_<topic>.md` (English). Include: goal, files to touch, hard constraints, and the verification commands the worker must run. Commit it: `docs(brief): add <topic> brief`.

## 2. Run the worker
Patch file `.claude/skills/dsh-worker/dsh-flash-max.yml` selects the model. Run in background from the repo root (PowerShell):

```powershell
"Read docs/BRIEF_<topic>.md and implement everything in it exactly. Run the verification commands and fix until they pass. Do not run git." |
  dsh --profile headless --patch .claude/skills/dsh-worker/dsh-flash-max.yml `
      --permission-mode workspace-write --approval-policy never - *> logs/dsh-<topic>.log
```

- `logs/` is gitignored. Max effort reasons for a long time before writing files; a growing log with no new files is normal.
- Follow-up in the same session: `--session-id <id>` (id is in the log / `~/.dsh/sessions`).
- `MISSING_CREDENTIAL` or `ACCOUNT_SIGN_IN_REQUIRED`: the user must sign in through the DeepSeek Harness desktop app.

## 3. Review
- Read the diff (`git status`, `git diff`). Check the brief's constraints, not only that tests pass.
- Run the checks listed in `CLAUDE.md` yourself.
- Problems: write a short fix brief (or append to the log session) and run the worker again. Do not hand-edit code.

## 4. Commit
Split by concern, Conventional Commits, explicit paths, no co-author line:
`feat(server): ...`, `feat(player): ...`, `test(core): ...`, `docs(architecture): ...`.
