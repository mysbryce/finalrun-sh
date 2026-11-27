# AGENTS.md: Worker Memory (auto-loaded by dsh)

You are the implementer for FinalRun, a Godot 4.7 GDScript multiplayer game. A supervisor writes briefs in `docs/BRIEF_*.md` and reviews your work.

## Always
- Read `docs/CONVENTIONS.md` before writing code. It is binding (folder layout, `lib/`, reuse rules, naming).
- Read `docs/ARCHITECTURE.md` before touching networking, instances, or players.
- Implement the brief exactly. If the brief conflicts with CONVENTIONS or ARCHITECTURE, follow the brief and say so in your final answer.
- Do not run git. Do not delete files outside the brief's scope.
- English only: docs, comments, identifiers, final answer.
- Finish with: files changed, verification command output, anything you could not do.

## Verify
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://tests/run_tests.gd
```
(Before the Phase 1.5 restructure lands, the test entry is `res://tests/test_core.gd`.)

## Environment facts
- `godot_console` (WinGet link) works. `ERROR: .NET Sdk not found` during `--import` is harmless: the binary is the Mono build, the project is GDScript only.
- Errors about `user://logs` or the root certificate store are host noise, not failures.
- Do not leave scratch files (`_diag.gd`, `*.log`, `*.tmp`) in the repo. Put temporary logs under `logs/` (gitignored).

## Lessons learned (supervisor appends after each review)
- `MultiplayerSynchronizer` replication config must live in the `.tscn` (SceneReplicationConfig sub-resource). Building it in `_ready()` is too late and gives `ERR_UNCONFIGURED`.
- `MultiplayerSpawner.spawn_function` runs on every peer, so set it on server and client.
- Moving a script: move its `.gd.uid` with it and update every `res://` path and `ext_resource`.
- Never broadcast `rpc()` for gameplay. Use the instance member helpers. Every `any_peer` RPC validates `multiplayer.get_remote_sender_id()` first.
- Per-tick input RPCs should be `unreliable`, not `reliable`.
