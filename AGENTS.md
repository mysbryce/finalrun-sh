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
- A failed assertion aborts the test method, so nodes freed at its end leak (`ObjectDB instances leaked`). Free test nodes before asserting, or create and free them in a helper.
- Smoke drivers you write for a run must live under `tools/smoke/` and stay in the repo, so the supervisor can rerun them. Do not delete them.
- Rules that hold "for the whole party" must also hold at every time-delayed completion (channels) and at every way into the party (invite, accept), not only at the start action.
- `LootDrop._on_take` / `_can_access` only check ALIVE. Any pickup RPC must add range, line-of-sight and the COP seizure rule before it is wired.
- npm in this sandbox: the default cache is outside the workspace (`EPERM`), so pass `--cache <session temp dir>\npm-cache` to `npm install` / `npm ci`. Vitest needs `pool: 'threads'` (forks cannot spawn).
- Web UI source is `ui/web/` (layout in `docs/design/WEB_UI.md`); build output `ui/dist/` is generated: change the source and rebuild, never edit `ui/dist/`.
- Instance SubViewports use own_world_3d, so Viewport.world_3d is null there. Get a node's world with Node3D.get_world_3d() (or Viewport.find_world_3d()).
- The web page is zoomed with CSS `zoom` on `<html>` (`app/uiScale.ts`): anything placed with `position: fixed` from screen-px coords (dnd-kit `DragOverlay`, popovers at the cursor) must cancel the zoom, see `features/inventory/dragZoom.ts`.
- Keys never reach the web page in game: the CEF browser has `FOCUS_NONE` and `_set_panel_input` only frees the mouse. Keyboard shortcuts for a screen (Enter, Esc, Tab) are handled in Godot (`Main._unhandled_input`) and forwarded; page key handlers only work in the dev preview.
- The Hud is a `CanvasLayer` (layer 1) whose full-screen browser texture eats clicks while a panel is open: native Godot UI that must show above it needs its own `CanvasLayer` with a higher layer (constant in `GameConst`).
- `Hud.page_ready`-style signals fire on every page load (also after boot, e.g. Vite reloads with `--ui-dev`): handlers for one-off flows must null-check their state object.
- Run `npm run test` (vitest) from PowerShell with a `d:\...` path. From Git Bash the cwd is `D:/...`; the drive-letter case mismatch loads vitest twice and every suite fails with "Vitest failed to find the current suite".
- Godot `_input` runs children first: a parent consuming an event in `_input` does not shield child SubViewports (they got it already). Gate gameplay on its own state (captured mouse, panel open), not on `set_input_as_handled` in Main.
- A `SubViewportContainer` with the default `MOUSE_FILTER_STOP` swallows clicks before root `_unhandled_input`; the `Instances` container uses `MOUSE_FILTER_PASS` so mouse bindings reach Main.
- `Callable.bind(x)` appends the bound args after the signal's own args: for `signal cancelled(reason)` connected with `handler.bind(record)`, declare `func handler(reason, record)`. The wrong order fails at runtime with "Cannot convert argument 1" and the handler never runs.
