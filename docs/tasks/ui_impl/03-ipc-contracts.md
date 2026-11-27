# ui_impl 03: typed IPC for the new screens (protocol, bridge, Hud snapshot replay)

Design source: `docs/ui-design/DATA_CONTRACTS.md` (read "Envelope and replay", "Existing and extended TS types", "New TS types"). README "Implementation order" step 3. This card only adds the plumbing; no screen uses it yet.

## Rules
- Web `ui/web/src/`: `lib/` never imports `features/`; `import type` for types; no new packages. Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'` configured; leave the Vite dev server on 5173 running; `ui/dist/assets` is not readable for you (the build result is enough).
- Godot: `ui/` never references `ServerManager`; `Hud` emits signals and `Main` wires them. Tests extend `TestCase` and run from `tests/run_tests.gd`. No magic numbers in features.

## Files
- modify: `ui/web/src/lib/ipc/protocol.ts`, `ui/web/src/lib/ipc/bridge.ts`, `ui/web/src/lib/ipc/bridge.test.ts`, `ui/web/src/features/search/demoSearch.ts`, `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`

## Steps
1. `protocol.ts`:
   - `HudState` adds the four optional fields exactly as in DATA_CONTRACTS (`weaponsLocked?`, `heistAlert?`, `surrenderAvailable?`, `channels?`).
   - `SearchItem` adds `w: number; h: number; slot: number` (Godot `Hud.search_view` already sends them via `item_view`; check and report). Update `features/search/demoSearch.ts` so every demo item has `w`/`h` (mix 1x1, 1x2, 2x1, 2x2) and `slot: -1`, otherwise `tsc` fails.
   - Add every type from the "New TS types" block verbatim (`BootPhase` ... `TransferView`), keeping the file's one-field-per-line formatting style.
   - `GodotToPage` adds `{ type: 'boot'; data: BootView }`, `{ type: 'lobby'; data: LobbyView }`, `{ type: 'party'; data: PartyView | null }`, `{ type: 'settings'; data: SettingsView }`, `{ type: 'transfer'; data: TransferView | null }`, `{ type: 'game_overlay'; data: GameOverlayView | null }`.
2. `bridge.ts`: `BridgeDeps` adds optional setters `setBoot?`, `setLobby?`, `setParty?`, `setSettings?`, `setTransfer?`, `setGameOverlay?` (typed with the new views; nullable where the message allows null). `handleMessage` dispatches the six new `type`s to them (missing setter = ignore). Existing cases unchanged. `request` already takes `timeoutMs`; leave it.
3. `bridge.test.ts`: each new type reaches its setter with the payload; `party`/`transfer`/`game_overlay` with `data: null` pass `null`; a new type with no setter does not throw.
4. `Hud.gd` generic snapshot cache for the new message types:
   - `var _snapshots: Dictionary = {}` (type -> JSON string of the full message).
   - `func publish(type: String, data: Variant) -> void`: builds `{"type": type, "data": data}`, sends it with `_send_json`; if `data == null` erases `_snapshots[type]`, else stores the JSON. Doc comment: for `boot`, `lobby`, `party`, `settings`, `transfer`, `game_overlay`; replayed on page `ready`.
   - In the `ready` branch of `_on_ipc_message`, after the existing `route` send and before search/inventory replay, send every cached snapshot JSON (any order).
   - `hud`, `search`, `inventory` keep their existing paths (do not route them through `publish`).
5. `tests/ui/hud/test_hud.gd`: a `Hud.new()` (no browser, so `_send_json` is a no-op; free it after) — `publish("lobby", {"canPlay": true})` stores a JSON string containing `"type":"lobby"`; `publish("lobby", null)` removes it; publishing `boot` and `transfer` keeps two entries. Read the file first and follow its style.
6. Checks: in `ui/web/`: `npm run test`, `npm run build`. From `d:\FinalRun`: `godot_console --headless --path . --import`, then `godot_console --headless --path . -s res://tests/run_tests.gd`.

## Do not
- No screens, routes or stores; no `Main.gd` changes; no request methods yet. Do not touch `docs/ui-design/`. Do not run git.

## Done when
- Web tests and build pass; Godot import has no script/parse errors (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); tests print `ALL TESTS PASSED`.
- Final answer: files changed, whether `search_view` already sends `w`/`h`/`slot`, web test summary line, build output list, last 3 Godot test lines.
