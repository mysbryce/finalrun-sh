# FinalRun

3D multiplayer extraction crime sandbox. Godot 4.7 (GDScript only), server-authoritative ENet multiplayer.
Architecture spec: `docs/BRIEF_core_systems.md`. Scene tree and sync rules: `docs/ARCHITECTURE.md`.
Folder structure, lib/utils placement, and reuse rules: `docs/CONVENTIONS.md` (binding for every brief and worker run).

## Roles
> **Temporary override (owner, 2026-11-27): dsh is paused.** Until the owner says to switch back, the code worker is a subagent: `Agent` with `model: "opus"` (Opus 5.5) and `effort: "medium"`. Same task cards and rules as dsh. The prompt must tell it to read `AGENTS.md` first (dsh auto-loaded it; a subagent does not), then the card, do exactly its steps, run Done-when, not run git, and report the card's final-answer items. Claude still does not write game code.

- Claude is the supervisor: writes briefs, reviews output, runs checks, commits. Claude does NOT write game code.
- All code is written by the DeepSeek worker through the `dsh` CLI. Use the `dsh-worker` skill (`.claude/skills/dsh-worker/SKILL.md`).
- Small non-code files (briefs, docs, config, this file) may be edited by Claude directly.

## Asset tools (owner, 2026-11-27)
- **Blender MCP**: the owner keeps Blender open with the MCP server running. For model work (characters, outfits, props, LODs, GLB export) use the `mcp__blender__*` tools directly, no need to ask first. Follow `docs/design/ART_DIRECTION.md` and the `godot-export` workflow.
- **Codex image generation**: spawn Codex CLI freely to generate textures, images and other assets for the game: `codex exec -C d:\FinalRun --enable image_generation "<prompt>"` (codex-cli 0.160.1, `image_generation` is stable and on by default). Tell it the exact output path under `assets/` and the size/format; review every image before committing.
- **Codex follow-ups**: when Codex asks back (open questions, a `.failed` marker), answer by resuming its thread `FinalRun` from this workspace (sessions are filtered by cwd, so run in `d:\FinalRun`): `codex exec resume FinalRun -m gpt-6.1-sol -c sandbox_mode="workspace-write" - < answers.md` (prompt on stdin; the config default `gpt-6.2-sol` is rejected for ChatGPT-account CLI runs). If it fails with "thread already has an active writer" (the owner's Codex app has the thread open), use `codex exec fork FinalRun ...` with the same flags. The supervisor decides the answers with sensible defaults, tells the owner which ones, and keeps going on the goal without waiting.
- Originality still applies: our own designs only, never imitate or reuse another game's characters, art or assets (nothing from `E:\ROBRUN`). Record the source/license of every asset in `assets/CREDITS.md` (generated ones: "generated with Codex image generation, owned by the project").

## Git
- Commit after every completed action. Conventional Commits: `type(scope): summary` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`).
- Scopes: `server`, `player`, `world`, `net`, `docs`, `tooling`.
- No `Co-Authored-By` or any Claude attribution in commits or PRs.
- Stage explicit paths. Never commit `.godot/`.

## Language
- All docs, briefs, code comments, and commit messages in English.

## Checks
- Parse/import: `godot_console --headless --path . --import`
- Tests: `godot_console --headless --path . -s res://tests/run_tests.gd` must print `ALL TESTS PASSED` (until the restructure lands: `res://tests/test_core.gd`).

## Token-saving shell (rtk)
- `rtk` 1.2.1 (oss edition) is installed globally; the `rtk hook claude` PreToolUse hook rewrites Bash commands automatically. In PowerShell, prefix by hand.
- Use rtk for: `git status`, `git log`, `ls`, `grep`/`find` sweeps, `git add`/`commit` output.
- Never filter what a review or check depends on: `git diff`, `git show`, `godot_console` (import/tests), `dsh` runs and their logs. These are in `exclude_commands` in `%APPDATA%\rtk\config.toml`; in PowerShell just call them without `rtk`.
- If rtk trims output it prints `[full output: rtk recall <hash>]`. Run that before drawing conclusions. `rtk bypass <cmd>` runs a command unfiltered.

## Worker effort (task cards)
- Supervisor thinks, worker types. Split each brief into small step-by-step task cards (`docs/tasks/<topic>/NN-<slug>.md`, template in the `dsh-worker` skill) and run one card per dsh run.
- deepseek-flash accepts only `low`, `high`, `max`. Default `low`; `high` after one failure; `max` after two failures or for net races the card cannot spell out.
- Write the next card while the current one runs. Parallel runs only when file lists do not overlap.

## Memory
- Auto memory is off for this project (`.claude/settings.json`).
- Supervisor memory: this file. Worker memory: `AGENTS.md` (auto-loaded by dsh on every run).
- After each review, append new gotchas to `AGENTS.md` → "Lessons learned" (one line each), so the worker does not repeat a mistake. Project-wide rules go here.

## EGM reviewers (use before handing work to dsh)
Run as subagents (`subagent_type: egm:<name>`), pointing them at the file path. Fix findings in the doc, then run dsh.

| When | Reviewer(s) |
|---|---|
| Every brief before dsh (non-trivial) | `egm-implementation-readiness`: missing details, ambiguity, untestable steps |
| Brief that touches existing code / refactor | + `egm-codebase-details`: paths, names, reuse vs the real code |
| New system design (`docs/design/*`) | `egm-design` + `egm-inventive-catalyst` (contradictions, rule conflicts) |
| New phase or scope growth (roadmap) | `egm-zoom-out`: cut overbuild, YAGNI |
| Big phase-level brief (3+ reviewers) | `egm-synthesizer` to run them in parallel and merge findings |
| Human-facing docs (README, ARCHITECTURE) | `egm-comprehension`, `egm-structural`, `egm-style` |
| Per-folder README docs (after big restructure) | `egm-bootstrap-orchestrator` |
Skip EGM for tiny fixes (one file, obvious change).

## What to give dsh
dsh starts fresh each run. It auto-loads `AGENTS.md`; everything else must be in the task card:
- Exact file paths to create or change, numbered steps with exact names, signatures, constants and values.
- The relevant rules copied from `docs/CONVENTIONS.md` / `docs/ARCHITECTURE.md` (not "read the whole doc").
- Existing helpers in `lib/` to reuse.
- Tests to add, Done-when commands, what the final answer must report.
- For fix cards: the failing output and the reviewer findings, pasted in.
Do not give dsh: chat history, open design questions (decide them first), or Thai text.
