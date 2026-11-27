# ui_impl 06: Esc pause menu (Resume, Leave to Lobby, Quit) and panel input gating

Design source: `docs/ui-design/04-hud.md` ("Pause menu" drawing and layout rows A01-A09, "Life and outcome surfaces" -> Pause), `docs/ui-design/flow.md` rows `/pause`, "HUD -> Pause -> HUD", "Pause -> lobby", and `docs/ui-design/DATA_CONTRACTS.md` (`pause.resume`, `session.leave`, `app.quit`). README step 13. Cards 04/05 added the boot flow, the lobby (`Main._show_lobby`, `Hud.show_lobby`), `Hud.quit_requested`, `Hud.publish`. Read `main/Main.gd`, `ui/hud/Hud.gd`, `features/player/Player.gd`, `features/player/PlayerCamera.gd` as they are now.

## Decisions for this card (supervisor)
- Menu only. The adjoining party panel (A10-A31) comes in the next card: do not render it, do not send `party`.
- Pause does not pause the game (session continues). While any panel is open (route other than `/`), the cursor is free and the player does not move or act.
- Settings button: disabled with `Coming later` until the settings card (same as the lobby).
- Esc is handled in Godot (keys never reach the page). Priority on Esc, first match wins: inventory open -> close it; body search open -> request the search close (server closes it); pause open -> resume; route `/` while connected, not booting, not in the lobby, and a local player exists -> open pause.
- Leave to Lobby: confirm in the page (`Modal`), then `session.leave`: Main closes the ENet peer itself and shows the lobby with status `disconnected`, error null (no server-side change; the server sees a normal disconnect).

## Rules
- Godot: `ui/` never references `ServerManager`; `Hud` emits signals and `Main` wires them. No magic numbers. Tests extend `TestCase`, mirror the source tree.
- Web `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `import type`; no new packages. Reuse `lib/ui` (`Button`, `Modal`, `Panel`).
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'` configured; do not start a Vite dev server; `ui/dist/assets` is not readable for you.

## Files
- create: `ui/web/src/features/pause/PauseScreen.tsx`, `ui/web/src/features/pause/PauseScreen.test.tsx`
- modify: `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`, `main/Main.gd`, `features/player/Player.gd`, `features/player/PlayerCamera.gd`, `ui/web/src/app/router.tsx`, `ui/web/src/main.tsx`

## Steps
### Godot
1. `Hud.gd`:
   - `func is_pause_open() -> bool` (`_route == "/pause"`), `func open_pause() -> void` (only from `/`: navigate `/pause`, `_set_panel_input(true)`), `func close_pause() -> void` (only when open: navigate `/`, `_set_panel_input(false)`), `func is_panel_open() -> bool` (`_route != "/"`).
   - `func request_search_close() -> void`: emits `search_close_requested(_search_target)` when a search is open.
   - Signal `session_leave_requested`. `route_request`: `pause.resume` -> action `["pause_resume"]`, `session.leave` -> `["session_leave"]` (ok `{}`; `# ponytail:` the contract's `busy`/`not_available` deferred). `_on_ipc_message`: `pause_resume` -> `close_pause()`; `session_leave` -> emit `session_leave_requested`.
   - `show_lobby` must also close the pause route state (it navigates to `/lobby` anyway; make sure `is_pause_open()` is false afterwards).
2. `Main.gd` `_unhandled_input`:
   - Esc (`KEY_ESCAPE`) follows the priority in the decisions (replace the current `close_inventory()` branch).
   - While `_hud.is_panel_open()`: only Esc and Tab are handled; every other gameplay/debug key returns early (Tab keeps today's `toggle_inventory`, which already ignores other panels).
3. `Main.gd`: `session_leave_requested` -> `func _leave_session() -> void`: if no peer, return; `_peer.close()`, `multiplayer.multiplayer_peer = null`, clear `_search_items`, then `_show_lobby(null)` (status `disconnected`, error null; add the null-error case to `_show_lobby` if it does not exist). Make sure `_on_server_disconnected` does not show the lobby a second time (guard with `_lobby != null`).
4. `PlayerCamera.gd`: remove the Esc branch that sets `MOUSE_MODE_VISIBLE` (Esc now belongs to the pause menu). Keep the left-click recapture branch (recovers the cursor after alt-tab) but only when no panel freed the cursor: it must not run while the browser has the mouse (`_unhandled_input` does not receive clicks the browser consumed; check and report that this holds with the browser's `MOUSE_FILTER_STOP`).
5. `Player.gd` `_read_input`: return `Vector2.ZERO` when `Input.mouse_mode != Input.MOUSE_MODE_CAPTURED` (no movement while a panel or the pause menu has the cursor). Comment why.
6. Tests: `test_hud.gd`: `route_request` maps `pause.resume` and `session.leave`; a `Hud.new()` (no browser): `open_pause()` from `/` sets `/pause` and `is_panel_open()`; `close_pause()` returns to `/`; `open_pause()` does nothing while `/inventory`. Free the node after.
### Web
7. `features/pause/PauseScreen.tsx` (positions from the layout table, absolute base px):
   - Dim `fixed inset-0 bg-zinc-950/55`; panel (A02) `bg-zinc-900 rounded-md`; title `Paused` (A03, panel heading 18/24); context `Session continues` (A04, 14/20 zinc-300).
   - Buttons 312 x 40 at A05-A08: `Resume` (primary) -> `request('pause.resume')`; `Settings` (secondary, disabled, `title="Coming later"`, visible small `Coming later`); `Leave to Lobby` (secondary) -> `Modal` title `Leave to lobby?`, body `You will disconnect from this server. Your character stays where the server puts it.`, `Cancel` (safe focus) / `Leave` (primary, `busy` while pending) -> `request('session.leave')`; `Quit` (secondary) -> `Modal` `Quit FinalRun?` -> `request('app.quit')`.
   - Feedback (A09): request error text (`Could not resume.`, `Could not leave the session.`, `Could not quit.`) in red-400 12/16, cleared on the next action.
8. `router.tsx`: `/pause` -> `PauseScreen`; the HUD stays visible under it (do not hide `HudScreen` on `/pause`). `main.tsx`: dev preview `#pause` (demo HUD + navigate `/pause`).
9. `PauseScreen.test.tsx`: Resume sends `pause.resume`; Leave to Lobby opens the modal with Cancel focused, Leave sends `session.leave`; Quit modal sends `app.quit`; Settings is disabled; a rejected request shows the feedback text.
10. Checks: `npm run test`, `npm run build` (in `ui/web/`); `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`; smoke `pwsh tools/smoke_local.ps1 -Clients 1`, wait 15 s, confirm connect + spawn and no `SCRIPT ERROR`, then `pwsh tools/smoke_local.ps1 -Stop` (never pipe the script's output). The Esc/pause path needs a human: say so in the final answer.

## Do not
- No party panel, no settings screen, no server code changes, no new gameplay rules. Do not touch `docs/ui-design/`. Do not run git.

## Done when
- Web tests and build pass; Godot import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke clean.
- Final answer: files changed/created, the PlayerCamera click finding (step 4), web test summary line, build output list, last 3 Godot test lines, smoke result, what still needs a manual check.
