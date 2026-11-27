# ui_impl 14: life outcome receipts and the transfer surface in Godot

Design source: `docs/ui-design/04-hud.md` section 4 "Life and outcome surfaces" (Death, Arrest, Transfer bullets), the visibility matrix, section 5 first paragraph (receipt dismissal), Decision 5; `docs/ui-design/flow.md` routes `/` with receipt, `/death`, `/arrest`, `/transfer` and transitions; `docs/ui-design/DATA_CONTRACTS.md` messages `transfer` and `game_overlay`, types `ReceiptTiming`, `GameOverlayView`, `TransferView`, requests `overlay.dismiss` and `transfer.return_to_lobby`, the receipt paragraph. Card 14b builds the page against the same contract (in parallel). Read first: `features/transfer/TransferService.gd` (all of it), `features/player/PlayerService.gd` (`transfer_to_motel` wrapper, the four direct `_transfers.transfer_to_motel(peer_id)` calls in `handle_peer_joined`, `surrender`, `_transfer_after_death`, `_handle_extraction`, `_on_player_life_state_changed`, `_send_mask_channel`), `features/player/PlayerRoleController.gd` (`LIFE_CAUSES`), `features/downed/DownedService.gd` (the cuff completion that notifies "You were cuffed and sent to Motel", `_send_client`), `autoload/ServerManager.gd` (`client_load_instance`, `client_downed_channel` and its signal), `main/Main.gd` (`_start_client` connects, `client_show_instance`, `_leave_session`, `_show_lobby`, `_on_server_disconnected`, `_on_escape`, `_unhandled_input`, `_input`), `ui/hud/Hud.gd` (`route_request`, `_on_ipc_message`, `publish`, `_process`, `show_lobby`, `end_boot`, `end_lobby`, `close_search`, `close_inventory`, `close_pause`, `close_settings`, `is_panel_open`, `_navigate`, `_set_panel_input`, `_settings_origin`), `tests/features/downed/test_cuff.gd`, `tests/features/downed/test_downed_channels.gd` (its FakeHost), `tests/ui/hud/test_hud.gd`.

## Decisions for this card (supervisor)

### Server: transfer reason and life outcome
- GameConst, right after `TRANSFER_TIMEOUT_SECONDS` (line 29): `TRANSFER_REASON_JOIN := "join"`, `TRANSFER_REASON_TRAVEL := "travel"`, `TRANSFER_REASON_EXTRACT := "extract"`, `TRANSFER_REASON_DEATH := "death"`, `TRANSFER_REASON_ARREST := "arrest"`, `TRANSFER_CLIENT_SLACK_MS: int = 1000` (comment: the client's transfer clock starts after the server's; a disconnect within this much of the deadline counts as a timeout, and the client's own expiry waits this much longer than the server's). HUD section: `RECEIPT_MS: int = 900`.
- `TransferService.begin_transfer(peer_id: int, target: GameInstance, reason: String = GameConst.TRANSFER_REASON_TRAVEL)`; the RPC args become `[target.instance_id, target.map_name, reason]`. `transfer_to_motel(peer_id: int, reason: String)` passes it on. `handle_join_map` and `_handle_lootybay_entry` keep the default.
- PlayerService: the wrapper becomes `transfer_to_motel(peer_id: int, reason: String) -> bool` and passes `reason` through. The four direct calls become `_transfers.transfer_to_motel(peer_id, GameConst.TRANSFER_REASON_*)`: `handle_peer_joined` JOIN, `surrender` ARREST, `_transfer_after_death` DEATH, `_handle_extraction` EXTRACT. DownedService cuff: `_players.transfer_to_motel(target_peer, GameConst.TRANSFER_REASON_ARREST)`.
- Owner RPC on ServerManager next to `client_downed_channel`: `@rpc("authority", "call_remote", "reliable") func client_life_outcome(kind: String, cause: String)` emitting new signal `life_outcome_received(kind: String, cause: String)`. Kinds/causes are the `GameOverlayView` literals.
- PlayerService: `static func death_cause(life_cause: String) -> String`: `"bleedout"` -> `"bleed_out"`, `"finish"` -> `"finished"`, anything else -> `"other"`. Helper `func _send_life_outcome(peer_id: int, kind: String, cause: String) -> void` next to `_send_mask_channel`, sending `client_life_outcome` the same way.
- Each outcome is sent BEFORE the matching transfer call, so it reaches the client before `client_load_instance` (same reliable channel). Keep every existing notification text unchanged.
  - Death: in `PlayerService._on_player_life_state_changed`, after the hook call: `var peer_id := int(player.get("peer_id")) if player != null else 0`; `if new_state == RoleControllerScript.LifeState.DEAD and cause != "disconnect" and peer_id > 0: _send_life_outcome(peer_id, "death", death_cause(cause))`. (The deferred `_transfer_after_death` runs later.)
  - Surrender: right after `_notify(peer_id, "Surrendered: bag handed over, gear kept")`: `_send_life_outcome(peer_id, "arrest", "surrender")`.
  - Cuff: right after `_notify(target_peer, "You were cuffed and sent to Motel")`: `_send_client(target_peer, "client_life_outcome", ["arrest", "cuffed"])`.

### Client: ServerManager and Main
- `ServerManager.client_load_instance(instance_id: String, map_name: String, reason: String)`:
  ```gdscript
  if multiplayer.is_server():
  	return
  var ok := false
  var scene := get_tree().current_scene
  if scene != null and scene.has_method("client_show_instance"):
  	ok = bool(scene.call("client_show_instance", instance_id, map_name, reason))
  else:
  	push_error("client_load_instance: current scene cannot show instances")
  # A failed load is never acked: the server times out and disconnects the peer.
  if ok:
  	rpc_id(1, "client_instance_ready", instance_id)
  ```
- `Main.client_show_instance(instance_id: String, map_name: String, reason: String = GameConst.TRANSFER_REASON_TRAVEL) -> bool`: return false right away in server mode. First, `_hud.begin_transfer(map_name, instance_id, reason, Time.get_ticks_msec())`. Unknown map -> keep the `push_error`, `_hud.fail_transfer("map_load_failed")`, return false. After the instance is built and configured (end of today's body): `_hud.transfer_loaded()`, return true.
- `_on_life_outcome(kind: String, cause: String)` -> `_hud.show_receipt(kind, cause, Time.get_ticks_msec())`; connect `ServerManager.life_outcome_received` next to the other ServerManager connects in `_start_client`.
- `_leave_session(error: Variant = null)`: replace the `if _peer == null: return` guard with `if _peer != null: _peer.close(); _peer = null`; the rest stays, and the last line becomes `_show_lobby(error)`. Connect `_hud.transfer_return_requested.connect(_leave_session.bind("disconnected"))` next to the other Hud connects (`session_leave_requested` keeps calling it with the default).
- `_on_server_disconnected`: inside the existing `if _boot == null and _hud != null and _lobby == null:` branch:
  ```gdscript
  if _hud.fail_transfer_on_disconnect(Time.get_ticks_msec()):
  	_create_client_view_container()
  	_search_items.clear()
  	_hud.clear_party_session()
  else:
  	_show_lobby("disconnected")
  ```
- `_on_escape`: directly after the Settings early return: `if _hud.dismiss_receipt_by_key(): return`.
- `_unhandled_input` key branch, directly after `if _boot != null or _lobby != null: return`: `if (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER) and _hud.is_transfer_failed(): _leave_session("disconnected"); get_viewport().set_input_as_handled(); return`. (Tab is not needed: the failure screen has one button.)
- `_input`: `if _server_mode: return`; then `if _capture != null:` keep the feed/consume/finish lines and add `return` at the end of that block; then: `if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and _hud != null and _hud.dismiss_receipt_by_click(): get_viewport().set_input_as_handled()`. Comment: mouse events reach the `Instances` SubViewportContainer in the GUI pass, after `_input`, so consuming here keeps the dismissing click from firing; `# ponytail:` receipts only follow a Motel respawn where weapons are locked, so a leaked click at worst shows "Weapons are locked here".

### Client: Hud state, routes and input
- New state: `var _transfer: Dictionary = {}` (exactly the `TransferView` keys: `mapName`, `instanceId`, `stage`, `reason`, `progress`, `error`), `var _transfer_started_ms: int = 0`, `var _receipt: Dictionary = {}` (`{"receiptId", "kind", "cause", "started_ms", "player"}`), `var _next_receipt: int = 1`, `var _base_input: String = ""`. New signal `transfer_return_requested`. `const BASE_ROUTES := ["/", "/transfer", "/death", "/arrest"]`.
- Statics:
  - `static func base_route(transfer_active: bool, receipt_kind: String, new_spawn: bool) -> String`: transfer -> `"/transfer"`; else `receipt_kind != "" and not new_spawn` -> `"/" + receipt_kind`; else `"/"`.
  - `static func receipt_view(receipt: Dictionary, ticks_ms: int) -> Variant`: null when empty or `ticks_ms - started_ms >= GameConst.RECEIPT_MS`; else `{"receiptId", "remainingMs": clampi(RECEIPT_MS - (ticks_ms - started_ms), 0, RECEIPT_MS), "kind", "cause", "destination": GameConst.MAP_MOTEL}` plus `"bagForfeited": true, "gearKept": true` for `arrest`.
  - `static func transfer_disconnect_error(started_ms: int, now_ms: int) -> String`: `"transfer_timeout"` when `now_ms - started_ms >= TIMEOUT_MS - GameConst.TRANSFER_CLIENT_SLACK_MS` (where `TIMEOUT_MS = int(GameConst.TRANSFER_TIMEOUT_SECONDS * 1000.0)`), else `"disconnected"`.
  - `static func transfer_expired(started_ms: int, now_ms: int) -> bool`: `now_ms - started_ms >= TIMEOUT_MS + GameConst.TRANSFER_CLIENT_SLACK_MS` (the server can drop a transfer without spawning or disconnecting, e.g. "Instance became full during transfer").
- Helpers:
  - `func _close_panels() -> void`: the close block from `show_lobby` (`if is_search_open(): close_search(_search_target)`, `close_inventory()`, `close_pause()`), and `if _settings_origin == "/pause": _settings_origin = ""`. `show_lobby` uses it.
  - `func _new_spawn() -> bool`: player valid and `_player.get_instance_id() != int(_receipt.get("player", 0))`.
  - `func _current_base() -> String`: `base_route(not _transfer.is_empty(), String(_receipt.get("kind", "")), _new_spawn())`.
  - `func _base_stop(route: String) -> bool`: false for `/`; true for `/death` and `/arrest`; for `/transfer` true when a receipt is present or the transfer failed.
  - `func _base_key() -> String`: `_current_base() + "|" + str(_base_stop(_current_base()))`.
  - `func _show_base() -> void`: `var route := _current_base()`; `_navigate(route)` when it differs from `_route`; `_set_input(route != "/", _base_stop(route))`; `_base_input = _base_key()`.
  - `func _set_input(free_cursor: bool, stop: bool) -> void`: like today's `_set_panel_input` (return when there is no browser) with `mouse_filter` STOP/IGNORE from `stop` and `mouse_mode` VISIBLE/CAPTURED from `free_cursor`. `_set_panel_input(open)` becomes `_set_input(open, open)`.
- Ordering rule: set the new state FIRST, then `_close_panels()` (each close lands directly on the right base route), then `if BASE_ROUTES.has(_route): _show_base()`. Never call `_show_base()` while `/settings/*`, `/lobby` or `/splash` is shown: Settings stays open over a transfer or receipt (`# ponytail:` closing it goes to the base route), and capture/preview keep working.
- Transfer methods:
  - `begin_transfer(map_name, instance_id, reason, ticks_ms)`: `_transfer = {"mapName": map_name, "instanceId": instance_id, "stage": "loading", "reason": reason, "progress": null, "error": null}`, `_transfer_started_ms = ticks_ms`; `publish("transfer", _transfer)`; `_close_panels()`; guarded `_show_base()`. `# ponytail:` maps load synchronously, so `progress` stays null.
  - `transfer_loaded()`: no-op unless stage is `loading`; stage `waiting_for_spawn`; publish.
  - `fail_transfer(error: String)`: no-op when `_transfer` is empty or already `failed`; else stage `failed`, `error`, publish, guarded `_show_base()`.
  - `fail_transfer_on_disconnect(now_ms: int) -> bool`: false when `_transfer` is empty; else `fail_transfer(transfer_disconnect_error(_transfer_started_ms, now_ms))` (keeps an earlier error) and true.
  - `is_transferring() -> bool` (non-empty and not failed), `is_transfer_failed() -> bool`.
  - `clear_transfer()`: `_transfer = {}`, `publish("transfer", null)`.
  - In `_process`, before the `_page_ready` return: (a) when `_transfer` stage is `waiting_for_spawn`, the player is valid, `_instance` is valid and `_instance.instance_id == _transfer["instanceId"]` -> `clear_transfer()`; (b) else when `is_transferring()` and `transfer_expired(_transfer_started_ms, Time.get_ticks_msec())` -> `fail_transfer("transfer_timeout")`.
- Receipt methods (sent with `_send_json`, never `publish`, so replay never resends a stale `remainingMs`):
  - `show_receipt(kind, cause, ticks_ms)`: ignore kinds other than `death`/`arrest`. A newer receipt replaces the old one. `_receipt = {"receiptId": "r%d" % _next_receipt, "kind", "cause", "started_ms": ticks_ms, "player": _player.get_instance_id() if the player is valid else 0}`, `_next_receipt += 1`; send `{"type": "game_overlay", "data": receipt_view(_receipt, ticks_ms)}`; `_close_panels()`; guarded `_show_base()`.
  - `dismiss_receipt(receipt_id: String = "")`: no-op when `_receipt` is empty or (`receipt_id != ""` and it differs); else `_receipt = {}`, send `game_overlay` null, guarded `_show_base()`.
  - `dismiss_receipt_by_key() -> bool`: receipt present and `_route` in `BASE_ROUTES` -> `dismiss_receipt()`, true; else false. `dismiss_receipt_by_click() -> bool`: same but only when `_route == "/"`.
  - In `_process`, before the `_page_ready` return: when the receipt is at least `RECEIPT_MS` old (`Time.get_ticks_msec()`), `dismiss_receipt()`.
  - `ready` branch of `_on_ipc_message`: after the cached snapshots, when `_receipt` is not empty send `game_overlay` with `receipt_view(_receipt, Time.get_ticks_msec())`. Update the `publish` doc comment: `game_overlay` is sent directly (not cached) because its `remainingMs` must be fresh on replay.
- Base route refresh: in `_process`, before the `_page_ready` return and after the transfer/receipt checks: `if BASE_ROUTES.has(_route) and _base_key() != _base_input: _show_base()`.
- Replace each `_navigate("/")` + `_set_panel_input(false)` pair with `_show_base()`: `end_boot`, `end_lobby`, `close_search`, `close_inventory`, `close_pause`, and `close_settings` when the origin is empty. `is_panel_open()` stays `_route != "/"` (gameplay and debug keys stay off on `/transfer`, `/death`, `/arrest`).
- `show_lobby`: FIRST clear `_transfer` (with `publish("transfer", null)`) and `_receipt` (with `game_overlay` null sent), then `_close_panels()` and the rest as today.
- Requests in `route_request`:
  - `overlay.dismiss`: `receiptId` must be a String, else `bad_params`; `_ok_reply(id, {}, ["overlay_dismiss", receiptId])`. `_on_ipc_message`: `dismiss_receipt(String(action[1]))`.
  - `transfer.return_to_lobby`: `{"reply": null, "action": ["transfer_return_to_lobby", id]}`. `_on_ipc_message`: when `is_transfer_failed()`, `send_reply(id, true, {}, "")` then `transfer_return_requested.emit()`; else `send_reply(id, false, {}, "not_available")`.

## Rules
- Server authority: the server decides outcomes and the transfer reason; the page only presents. `features/` never import `autoload/` (use the injected host as existing services do); `ui/` never references `ServerManager`; Hud emits signals and Main wires them. No magic numbers (`GameConst.RECEIPT_MS`, `TRANSFER_TIMEOUT_SECONDS`, `TRANSFER_CLIENT_SLACK_MS`, the reason constants).
- Tests extend `TestCase`, mirror the source tree, have no setup/teardown hooks: compute values, free nodes, then assert. `Hud.new()` without adding it to the tree works for state tests (no browser, so no mouse changes); read private state with `hud.get("_route")` etc.; free it before asserting.

## Files
- modify: `lib/constants/GameConst.gd`, `features/transfer/TransferService.gd`, `features/player/PlayerService.gd`, `features/downed/DownedService.gd`, `autoload/ServerManager.gd`, `main/Main.gd`, `ui/hud/Hud.gd`, `tests/features/downed/test_cuff.gd`, `tests/ui/hud/test_hud.gd`
- create: `tests/features/player/test_life_outcome.gd`

## Steps
1. GameConst values.
2. TransferService and PlayerService reason plumbing; `death_cause`, `_send_life_outcome` and the three outcome sends; DownedService cuff reason + send.
3. ServerManager: `client_load_instance` as written above; `client_life_outcome` + signal.
4. Hud: everything in the Hud decisions.
5. Main: everything in the Main decisions.
6. Tests:
   - `test_life_outcome.gd`: `death_cause("bleedout") == "bleed_out"`, `("finish") == "finished"`, `("damage") == "other"`, `("redown") == "other"`. Plus: a `PlayerService.new()` with `_host` set to a FakeHost Node that records `_send_client_rpc(peer, method, args)` calls (copy the pattern from `test_downed_channels.gd`) and a `Player.tscn` instance with `peer_id` 20: `_on_player_life_state_changed(DOWNED, DEAD, "bleedout", player)` records `[20, "client_life_outcome", ["death", "bleed_out"]]`; with cause `"disconnect"` nothing is recorded. Free the nodes before asserting.
   - `test_cuff.gd`: `FakePlayers` gets `var last_reason: String = ""` and `func transfer_to_motel(_peer_id: int, reason: String) -> bool` recording it (plus appending `["transfer"]` to a shared log array); give the DownedService a FakeHost whose `_send_client_rpc` and `_notify` append to the same log. Assert `last_reason == "arrest"` and that `[<criminal peer>, "client_life_outcome", ["arrest", "cuffed"]]` comes before `["transfer"]` in the log.
   - `test_hud.gd` statics: `base_route` for (true, "death", false) -> `/transfer`, (false, "death", false) -> `/death`, (false, "arrest", false) -> `/arrest`, (false, "death", true) -> `/`, (false, "", false) -> `/`; `receipt_view` for empty -> null, death at started 1000 / now 1300 -> `remainingMs` 600 with kind/cause/destination, arrest -> `bagForfeited` and `gearKept` true, now 1900 -> null; `transfer_disconnect_error(1000, 9999)` -> `disconnected`, `(1000, 10000)` -> `transfer_timeout`; `transfer_expired(1000, 11999)` false, `(1000, 12000)` true; route `overlay.dismiss {receiptId: "r1"}` -> ok + action `["overlay_dismiss", "r1"]`, `{receiptId: 1}` -> `bad_params`; `transfer.return_to_lobby` -> reply null + action `["transfer_return_to_lobby", id]`.
   - `test_hud.gd` state and routes with `Hud.new()` (route starts at `/`): `show_receipt("death", "bleed_out", 1000)` -> `_route == "/death"`, `dismiss_receipt_by_click()` false, `dismiss_receipt("nope")` keeps the receipt, a second `show_receipt` gets a new id; `begin_transfer("Motel", "Motel-01", "death", 1000)` -> `_route == "/transfer"`, `is_transferring()`; `dismiss_receipt_by_key()` true and the route stays `/transfer`; `transfer_loaded()` -> stage `waiting_for_spawn`; `fail_transfer("map_load_failed")` then `fail_transfer_on_disconnect(20000)` -> true, error stays `map_load_failed`, `is_transfer_failed()`; `clear_transfer()` -> both false and `_route == "/"`. Separate Hud: receipt + transfer set, then `show_lobby({})` -> `_transfer` and `_receipt` empty and `_route == "/lobby"`. Separate Hud with `_route` set to `/settings/graphics`: `begin_transfer(...)` leaves `_route == "/settings/graphics"`.
7. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`; smoke `pwsh tools/smoke_local.ps1 -Clients 2` (call it plainly, never redirect or pipe its output), wait 20 s, both clients log `[Main] Client loaded instance` and spawn as in earlier smokes (the join transfer now goes through the transfer state), no `SCRIPT ERROR` / `Invalid` errors in client or server logs, then `pwsh tools/smoke_local.ps1 -Stop`. The page may not have the `/transfer` route yet (card 14b runs in parallel); a brief blank page there is expected.

## Do not
- No web changes. Do not edit `docs/`. Do not run git. Do not change any notification text.

## Done when
- Import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke clean.
- Final answer: files changed/created, last 3 Godot test lines, smoke result, and under "could not do": "receipt Esc/click dismissal, the death/arrest routes and transfer failure + Return to Lobby not exercised at runtime" plus anything else and why.
