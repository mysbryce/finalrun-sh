# ui_impl 05: lobby after a disconnect (Play, news, placeholder preview, Quit)

Design source: `docs/ui-design/02-lobby.md` (sections 1, 3 "Lobby with current capabilities", 4, 6, 7, 9), `docs/ui-design/flow.md` rows for `/lobby`, and `docs/ui-design/DATA_CONTRACTS.md` (`LobbyView`, `PatchNote`, `PatchNotesFile`, `lobby.join`, `lobby.news_retry`, `settings.open`, `app.quit`). README step 5. Card 04 added `main/BootFlow.gd` (`parse_endpoint`, `build_id`), `Main._connect_to_server()`, the splash route, Hud `quit_requested`, `publish(type, data)` and the snapshot replay. Read `main/Main.gd` and `ui/hud/Hud.gd` as they are now before changing them.

## Decisions for this card (supervisor)
- Today the lobby is reached only when the server connection drops after boot (`_on_server_disconnected`, or a connection failure while joining from the lobby). Leaving through Pause comes with the pause card.
- Only the "current capabilities" drawing: no Server ID field, no Quick Join, no party panel (`capabilities` all false, `party` null).
- Character preview: placeholder silhouette only (`appearance.status = "placeholder"`, `bodyType`/`slots` from `AppearanceData.default_for(0)` is NOT needed: send `bodyType: null`, `slots: {}`). `# ponytail:` comment in Main: 3D preview viewport when the semi-realistic characters land.
- Settings button: `settings.open` replies `not_available` until the settings card; the button is shown disabled with the hint `Coming later` (title attribute + visible small text).
- Quit asks for confirmation with the `Modal` from `lib/ui` (Cancel safe focus, then Quit) and sends `app.quit` (Hud already maps it to `quit_requested`).
- Ping shown as `null` (no RTT while disconnected; when connecting it stays null).
- Keys stay with the game (browser `FOCUS_NONE`): the lobby is used with the mouse; no Godot key handling is added for it.

## Rules
- Godot: `ui/` never references `ServerManager`; `Hud` emits signals and `Main` wires them. New numbers in `GameConst.gd`. Tests extend `TestCase`, mirror the source tree.
- Web `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages. Reuse `lib/ui` (`Panel`, `HeaderBar`, `Button`, `Modal`, `ProgressBar`).
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'` configured; do not start a Vite dev server; `ui/dist/assets` is not readable for you.

## Files
- create: `main/LobbyState.gd`, `tests/main/test_lobby_state.gd`, `ui/web/public/news.json`, `ui/web/src/features/lobby/LobbyScreen.tsx`, `lobbyStore.ts`, `lobbyCopy.ts`, `demoLobby.ts`, `LobbyScreen.test.tsx`
- modify: `main/Main.gd`, `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`, `ui/web/src/app/router.tsx`, `ui/web/src/main.tsx`

## Steps
### Godot
1. `main/LobbyState.gd`: `class_name LobbyState extends RefCounted`, pure data, builds `LobbyView`:
   - Fields: `status` (`ConnectionStatus` string, default `"disconnected"`), `error` (Variant null or `ConnectionError`), `player_name` (Variant, null), `news_status` (`"loading"`), `news_entries: Array`.
   - `func view() -> Dictionary` with exactly the `LobbyView` keys: `playerName`, `connection` `{status, serverId: null, pingMs: null, error}`, `capabilities` `{joinById: false, quickJoin: false, partyStaging: false}`, `canPlay` (true unless `status` is `"connecting"` or `"resolving"`), `party: null`, `appearance` `{status: "placeholder", bodyType: null, slots: {}}`, `news` `{status, entries}`.
   - `static func parse_news(text: String) -> Dictionary`: `{"status": "ready"|"failed", "entries": Array}`. Valid input is a `PatchNotesFile` (`{"entries": [...]}`) whose entries each have string `version`, `publishedOn`, `title`, `summary`; drop malformed entries; sort newest first by `publishedOn` (ISO date string compare), then `version`; non-JSON or no `entries` array -> `failed` with `[]`.
   - `static func load_news(path: String) -> Dictionary`: `FileAccess` read -> `parse_news`; missing file -> `failed`.
   - `GameConst.gd`: `NEWS_PATH: String = "res://ui/dist/news.json"`.
2. `Hud.gd`:
   - Signals `lobby_join_requested`, `lobby_news_retry_requested`.
   - `route_request`: `lobby.join` with `params.mode == "configured"` -> action `["lobby_join"]`; other modes -> `discovery_unavailable`; missing/invalid mode -> `bad_params`. `lobby.news_retry` -> `["news_retry"]`. `settings.open` -> error `not_available` (`# ponytail:` until the settings card). `_on_ipc_message` emits the signals.
   - `func show_lobby(view: Dictionary) -> void`: close search/inventory state if open (reuse the existing close paths without sending server requests), `publish("lobby", view)`, navigate `/lobby` if not there, `_set_panel_input(true)`.
   - `func end_lobby() -> void`: erase the `lobby` snapshot, navigate `/`, `_set_panel_input(false)`.
   - `_send_json`: also return early while `not _page_ready` (messages before the page's `ready` are lost anyway and are replayed on `ready`; this removes the `[CefTexture2D] Cannot send IPC message: no browser` warning at startup). Check the `ready` branch sets `_page_ready = true` before it sends.
3. `Main.gd`:
   - `var _lobby: LobbyState = null`. `func _show_lobby(error: Variant) -> void`: create `_lobby` if null (load news once with `LobbyState.load_news(GameConst.NEWS_PATH)`), set `status = "disconnected"` (or `"failed"` with the error when given), reset the client world (`_create_client_view_container()`, clear `_search_items`), `_hud.show_lobby(_lobby.view())`.
   - `_on_server_disconnected` (after boot, i.e. `_boot == null`): keep the existing peer reset, then `_show_lobby("disconnected")` with status `"disconnected"` and error `"disconnected"`.
   - `_on_connection_failed` while `_lobby != null` (joining from the lobby): status `"failed"`, error `"connection_failed"`, republish.
   - `lobby_join_requested`: if `_lobby == null` or status is `connecting`: return. Status `"connecting"`, error null, republish, `_connect_to_server()` (if the endpoint is invalid it must not quit while in the lobby: make `_connect_to_server` treat `_lobby != null` like `_boot != null`, reporting `invalid_endpoint` / `connection_failed` into the lobby state).
   - `_on_connected_to_server` while `_lobby != null`: `_hud.end_lobby()`, `_lobby = null` (the server's normal Motel transfer follows).
   - A lobby connect timeout: reuse `GameConst.BOOT_CONNECT_TIMEOUT_MS` (store the connect start ms; in `_process` before the `player == null` return, if `_lobby` status is `connecting` past the timeout: close the peer, status `"failed"`, error `"connection_timeout"`, republish).
   - `lobby_news_retry_requested`: reload news into `_lobby`, republish.
   - `_unhandled_input`: while `_boot != null` (after the Enter-skip branch) or `_lobby != null`, ignore the gameplay/debug keys (return before the `match`), so no server request is sent without a connection.
   - Header comment: mention the lobby.
4. Tests: `tests/main/test_lobby_state.gd` (`view()` keys and defaults; `canPlay` false while connecting; `parse_news` valid file sorted newest first, malformed entry dropped, bad JSON -> failed). `test_hud.gd`: `route_request` for `lobby.join` configured / `by_id` (`discovery_unavailable`) / missing mode (`bad_params`), `lobby.news_retry`, `settings.open` (`not_available`).
### Web
5. `ui/web/public/news.json`: `{"entries": [{"version": "0.2.0", "publishedOn": "2026-11-27", "title": "New boot, lobby and character", "summary": "Splash screen with retry, a lobby after disconnects, and the first CC0 base character with walk, sprint and downed poses."}]}` (Vite copies `public/` into `ui/dist/`, which is what `NEWS_PATH` reads; confirm `ui/dist/news.json` exists after the build).
6. `features/lobby/lobbyStore.ts` (zustand `{ lobby: LobbyView | null; setLobby }`), `lobbyCopy.ts` (`connectionLabel(status)`: `Disconnected`, `Resolving`, `Connecting`, `Connected`, `Connection failed`; `connectionErrorText(error)` for every `ConnectionError`, plain sentences, e.g. `disconnected` -> `The server closed the connection.`, `connection_failed` -> `Could not reach the server.`, `connection_timeout` -> `The server did not answer in time.`, `invalid_endpoint` -> `The server address is invalid.`, others similar).
7. `LobbyScreen.tsx`, positions from the layout table "Lobby with current capabilities" (absolute, base px, full `bg-zinc-950` surface):
   - Header: title `FinalRun`, player identity (`playerName ?? 'Player'`), connection state (`connectionLabel`, `aria-live="polite"`, ping text only when `pingMs` is a number).
   - Play panel: title `Play`, primary `Play` button (disabled + `loading` while `!canPlay`), feedback area: `connectionErrorText(error)` when error, `Connecting to server` + indeterminate `ProgressBar` while connecting. Play -> `request('lobby.join', { mode: 'configured' })`.
   - News panel: title `Patch notes`; `loading` -> `Loading patch notes`; `ready` with entries -> scrollable list (version + date small, title 14 600, summary 12/16) newest first as given; `ready` empty -> `No patch notes yet.`; `failed` -> `Patch notes could not load.` + `Retry` (quiet button, News action slot) -> `request('lobby.news_retry')`.
   - Character preview: title `Character`, placeholder silhouette (a simple inline SVG/CSS head-and-shoulders shape in zinc-700, `aria-hidden`) with the text `Preview coming soon` for `placeholder`, `Loading preview` for `loading`, `Preview unavailable` for `failed`; summary line `Body: <bodyType ?? 'Default'>`.
   - Footer: `Settings` (secondary, disabled, `title="Coming later"`, small `Coming later` text next to it), `Quit` (secondary) -> `Modal` "Quit FinalRun?" with `Cancel` (secondary, safe focus) and `Quit` (primary) -> `request('app.quit')`, primary `busy` while pending.
   - Renders nothing when `lobby` is null.
8. `router.tsx`: `/lobby` -> `LobbyScreen`; `RootLayout` hides `HudScreen` on `/lobby` too. `main.tsx`: wire `setLobby`; dev preview `#lobby` sets `DEMO_LOBBY` (disconnected with error `disconnected`, news ready with 2 entries) and navigates `/lobby`.
9. `LobbyScreen.test.tsx`: Play sends `lobby.join` with `{ mode: 'configured' }`; connecting disables Play and shows `Connecting to server`; error text for `disconnected`; news failed shows Retry sending `lobby.news_retry`; empty news text; Quit opens the modal with Cancel focused, confirming sends `app.quit`; Settings is disabled.
10. Checks: `npm run test`, `npm run build` (in `ui/web/`); `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`. Smoke: `pwsh tools/smoke_local.ps1 -Clients 1`, wait 15 s (client connected + spawned), then stop only the server process (first PID in `.smoke\pids.txt`, `Stop-Process -Id`), wait 5 s, confirm the client log has `[Main] Server disconnected` and no `SCRIPT ERROR` after it (add a `print("[Main] Lobby shown")` in `_show_lobby` and check for it), then `pwsh tools/smoke_local.ps1 -Stop` (never pipe the script's output).

## Do not
- No pause menu, settings, party staging, discovery or 3D preview. No server code changes. Do not touch `docs/ui-design/`. Do not run git.

## Done when
- Web tests and build pass, `ui/dist/news.json` exists; Godot import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke shows `[Main] Lobby shown` after the server stops, with no `SCRIPT ERROR`.
- Final answer: files created/changed, web test summary line, build output list, last 3 Godot test lines, smoke result, anything you could not do and why.
