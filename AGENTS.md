# AGENTS.md: Worker Memory (auto-loaded by dsh)

You are the implementer for FinalRun, a Godot 4.7 GDScript multiplayer game. A supervisor writes briefs in `docs/BRIEF_*.md` and reviews your work.

## Always
- Most runs give you a task card (`docs/tasks/<topic>/NN-<slug>.md`). The card is self-contained: do its steps in order, nothing more, and do not redesign. Read `docs/CONVENTIONS.md` or `docs/ARCHITECTURE.md` only if the card tells you to.
- If a step cannot be done as written (missing function, wrong path), stop and report it. Do not invent a workaround.
- For a full brief (`docs/BRIEF_*.md`): read `docs/CONVENTIONS.md` first, and `docs/ARCHITECTURE.md` before touching networking, instances, or players. If the brief conflicts with them, follow the brief and say so.
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

## Token-saving shell (rtk)
`rtk` is on PATH. It runs a command and prints a compact version of its output.
- Use `rtk` for noisy listing and search commands: `rtk ls <dir>`, `rtk find <dir> -name "*.gd"`, `rtk grep -rn <pattern> <dir>`, `rtk wc -l <files>`.
- Never use `rtk` for verification: run `godot_console --headless --path . --import` and `godot_console --headless --path . -s res://tests/run_tests.gd` plainly. You need every error line and the final `ALL TESTS PASSED`.
- Never use `rtk` when you check a reuse or safety rule that needs every match, for example "no broadcast `rpc(`" or "`lib/` imports no `features/`". Use plain `grep`/`Select-String` for those.
- If rtk output contains `[full output: rtk recall <hash>]`, it trimmed something. Run that command before you decide anything from the output.

## Lessons learned (supervisor appends after each review)
- `MultiplayerSynchronizer` replication config must live in the `.tscn` (SceneReplicationConfig sub-resource). Building it in `_ready()` is too late and gives `ERR_UNCONFIGURED`.
- `MultiplayerSpawner.spawn_function` runs on every peer, so set it on server and client.
- Moving a script: move its `.gd.uid` with it and update every `res://` path and `ext_resource`.
- Never broadcast `rpc()` for gameplay. Use the instance member helpers. Every `any_peer` RPC validates `multiplayer.get_remote_sender_id()` first.
- Per-tick input RPCs should be `unreliable`, not `reliable`.
- Life/role state changes go through one idempotent server function; every other path calls it (no direct writes).
- Test rule functions with real node shapes too, not only controllers (a `has_node_or_null` crash slipped through controller-only tests).
- Services are `RefCounted`: they own no Nodes or Timers. Tick them from `ServerManager._process` with an injected `now_ms`.
- `lib/utils` stays stateless: counters and ids live in a service.
