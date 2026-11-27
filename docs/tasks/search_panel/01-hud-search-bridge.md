# search_panel 01: Godot side of the body search panel (search messages, requests, mouse)

Design: `docs/design/WEB_UI.md` ("IPC protocol": `search` message, `search.take` / `search.close` methods; "Input"). Card 02 builds the page in parallel; do not touch `ui/web/` or `ui/dist/`.

## Context (already true)
- Server flow exists: `ServerManager.request_search_open(target)` -> server sends `client_search_contents(target_peer_id, items)` on open and on every change (`ServerManager.search_contents_received`), and `client_search_closed(target_peer_id, reason)` (`ServerManager.search_closed_received`). Take/close: `ServerManager.request_search_take(target_peer_id: int, item_uid: int)`, `ServerManager.request_search_close(target_peer_id: int)`. The server validates everything.
- Item dictionaries: `{"uid": int, "id": String, "value": int, "source": "bag" | "gear", ...}` (`source` may be missing: treat as `"bag"`).
- `main/Main.gd`: `_on_search_contents(target_peer_id, items)` stores `_search_items[target] = items.duplicate(true)`; `_on_search_closed(target_peer_id, reason)` erases it. Keys `T` (take first) and `Q` (close) stay.
- `ui/hud/Hud.gd` (`class_name Hud extends CanvasLayer`): `_browser` (CefTexture or null when headless), `_page_ready`, `_last_hud_json`, `_send_json(json)`, `_on_ipc_message(message)`: on `ready` sets `_page_ready = true`, `_last_hud_json = ""`, sends `{"type":"route","to":"/"}`; on `request` sends `JSON.stringify(reply_for(parsed))`. `static func reply_for(request) -> Dictionary` handles `ping` and `unknown_method`. `static func player_name(peer_id)`.
- Rule: `ui/` never references `ServerManager`; `Main.gd` wires signals. Tests extend `TestCase`; free nodes before asserting.
- `PlayerCamera` captures the mouse (`Input.MOUSE_MODE_CAPTURED`); the browser normally has `mouse_filter = MOUSE_FILTER_IGNORE`.

## Files
- modify: `ui/hud/Hud.gd`, `main/Main.gd`, `tests/ui/hud/test_hud.gd`

## Steps
1. `Hud.gd` signals (top of the class, after `extends`/doc comment):
   ```gdscript
   ## The page asked to take an item from the open body search. Main forwards it to the server.
   signal search_take_requested(target_peer_id: int, item_uid: int)
   ## The page asked to close the open body search.
   signal search_close_requested(target_peer_id: int)
   ```
2. `Hud.gd` pure static helpers:
   - `static func item_label(item_id: String) -> String`: `"cop_pistol"` -> `"Cop pistol"`: replace `"_"` with `" "`, uppercase only the first character; `""` -> `""`.
   - `static func search_view(target_peer_id: int, items: Array) -> Dictionary`: `{"target": target_peer_id, "title": "Body of %s" % player_name(target_peer_id), "items": [...]}`, each item `{"uid": int(item.get("uid", 0)), "id": String(item.get("id", "")), "label": item_label(String(item.get("id", ""))), "value": int(item.get("value", 0)), "source": String(item.get("source", "bag"))}`, same order.
   - Replace `reply_for` with `static func route_request(request: Dictionary, open_target: int) -> Dictionary` returning `{"reply": <reply dict>, "action": <Array>}`:
     - `var id := int(request.get("id", 0))`, `var method := String(request.get("method", ""))`, `var params: Dictionary = request.get("params", {}) if request.get("params", {}) is Dictionary else {}`.
     - `ping` -> reply `{"type": "reply", "id": id, "ok": true, "data": {"pong": true}}`, action `[]`.
     - `search.take`: `target := int(params.get("target", 0))`, `uid := int(params.get("uid", 0))`. If `open_target == 0 or target != open_target` -> error `no_search`; elif `uid <= 0` -> error `bad_params`; else reply `ok: true, "data": {}`, action `["take", target, uid]`.
     - `search.close`: `target != open_target or open_target == 0` -> error `no_search`; else `ok: true, "data": {}`, action `["close", target]`.
     - anything else -> error `unknown_method`.
     - Error reply shape: `{"type": "reply", "id": id, "ok": false, "error": <text>}`, action `[]`.
3. `Hud.gd` state: `var _search_target: int = 0`, `var _search_items: Array = []`, `var _route: String = "/"`.
4. `Hud.gd` public methods:
   ```gdscript
   ## Body search contents arrived (first open or a change).
   func open_search(target_peer_id: int, items: Array) -> void:
       _search_target = target_peer_id
       _search_items = items.duplicate(true)
       _send_json(JSON.stringify({"type": "search", "data": search_view(_search_target, _search_items)}))
       if _route != "/search":
           _navigate("/search")
           _set_panel_input(true)

   ## The server closed the search (or the player walked away).
   func close_search(target_peer_id: int) -> void:
       if target_peer_id != _search_target:
           return
       _search_target = 0
       _search_items = []
       _send_json(JSON.stringify({"type": "search", "data": null}))
       _navigate("/")
       _set_panel_input(false)

   func is_search_open() -> bool:
       return _search_target != 0
   ```
   Private:
   ```gdscript
   func _navigate(to: String) -> void:
       _route = to
       _send_json(JSON.stringify({"type": "route", "to": to}))

   ## Panels take the mouse: the page gets clicks and the cursor is free.
   func _set_panel_input(open: bool) -> void:
       if _browser == null or not is_instance_valid(_browser):
           return
       _browser.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
       Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
   ```
5. `Hud._on_ipc_message`:
   - `ready`: keep `_page_ready = true` and `_last_hud_json = ""`; replace the fixed route send with `_send_json(JSON.stringify({"type": "route", "to": _route}))`, then if `_search_target != 0` also send the `search` message (same JSON as in `open_search`).
   - `request`: `var routed := route_request(parsed, _search_target)`; `_send_json(JSON.stringify(routed["reply"]))`; `var action: Array = routed["action"]`; if `action.size() == 3 and action[0] == "take"`: `search_take_requested.emit(int(action[1]), int(action[2]))`; elif `action.size() == 2 and action[0] == "close"`: `search_close_requested.emit(int(action[1]))`.
6. `main/Main.gd`:
   - `_start_client()`, right after `add_child(_hud)`: `_hud.search_take_requested.connect(ServerManager.request_search_take)` and `_hud.search_close_requested.connect(ServerManager.request_search_close)`.
   - `_on_search_contents`: after the existing lines add `if _hud != null: _hud.open_search(target_peer_id, items)`.
   - `_on_search_closed`: after the existing lines add `if _hud != null: _hud.close_search(target_peer_id)`.
7. `tests/ui/hud/test_hud.gd`:
   - Replace `test_reply_ping` / `test_reply_unknown_method` with the same checks on `Hud.route_request(req, 0)["reply"]` (and `["action"] == []`).
   - `test_item_label`: `"cop_pistol" -> "Cop pistol"`, `"jewelry" -> "Jewelry"`, `"" -> ""`.
   - `test_search_view`: `Hud.search_view(7, [{"uid": 12, "id": "cop_pistol", "value": 0, "source": "gear"}, {"uid": 13, "id": "jewelry", "value": 300}])` -> target 7, title `"Body of Player 7"`, two items, first `{"uid": 12, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear"}`, second source `"bag"`.
   - `test_route_search_take`: open target 7: `{"id": 1, "method": "search.take", "params": {"target": 7, "uid": 12}}` -> reply ok true, action `["take", 7, 12]`; target 8 -> ok false, error `no_search`, action `[]`; uid 0 -> error `bad_params`; open target 0 -> error `no_search`.
   - `test_route_search_close`: open 7, `{"id": 2, "method": "search.close", "params": {"target": 7}}` -> ok, action `["close", 7]`; open 0 -> error `no_search`.
   - `test_open_and_close_search_headless`: `var hud := Hud.new()`, add to root; `hud.open_search(7, [{"uid": 1, "id": "jewelry", "value": 300}])`; `var opened := hud.is_search_open()`; `hud.close_search(8)`; `var still_open := hud.is_search_open()`; `hud.close_search(7)`; `var closed := not hud.is_search_open()`; `hud.free()`; assert `opened`, `still_open`, `closed`.

## Do not
- No server or RPC changes. Do not touch `ui/web/`, `ui/dist/`. Do not remove the T/Q keys. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
