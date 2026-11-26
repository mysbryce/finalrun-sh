# FinalRun

3D multiplayer extraction crime sandbox. Godot 4.7 (GDScript only), server-authoritative ENet multiplayer.
Architecture spec: `docs/BRIEF_core_systems.md`. Scene tree and sync rules: `docs/ARCHITECTURE.md`.

## Roles
- Claude is the supervisor: writes briefs, reviews output, runs checks, commits. Claude does NOT write game code.
- All code is written by the DeepSeek worker through the `dsh` CLI. Use the `dsh-worker` skill (`.claude/skills/dsh-worker/SKILL.md`).
- Small non-code files (briefs, docs, config, this file) may be edited by Claude directly.

## Git
- Commit after every completed action. Conventional Commits: `type(scope): summary` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`).
- Scopes: `server`, `player`, `world`, `net`, `docs`, `tooling`.
- No `Co-Authored-By` or any Claude attribution in commits or PRs.
- Stage explicit paths. Never commit `.godot/`.

## Language
- All docs, briefs, code comments, and commit messages in English.

## Checks
- Parse/import: `godot_console --headless --path . --import`
- Tests: `godot_console --headless --path . -s res://tests/test_core.gd` must print `ALL TESTS PASSED`.

## Memory
- Auto memory is off for this project (`.claude/settings.json`). Persistent rules live in this file only.
