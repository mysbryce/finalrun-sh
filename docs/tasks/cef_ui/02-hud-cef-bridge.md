# cef_ui 02: Godot HUD drives the web UI through a CefTexture

Design: `docs/design/WEB_UI.md`. Card 01 builds the web page in parallel (`webui/` -> `ui/web/index.html`); do not touch `webui/` or `ui/web/`.

## Context (already true, do not change)
- `ui/hud/Hud.gd` (`class_name Hud extends CanvasLayer`) is a Label HUD today. `main/Main.gd` creates it on clients and calls only these public methods: `set_player(player: Node3D)`, `set_money(state: Dictionary)` (keys `cash`, `bag_value`, `notoriety`), `set_mask_channel(seconds: float, now_ms: int)`, `add_notification(text: String, now_ms: int)`. Keep these four exactly.
- Keep the existing static helpers `role_text`, `life_text`, `seconds_left`, `push_notification`, `prune_notifications` unchanged.
- The Godot CEF addon provides class `CefTexture` (extends `TextureRect`): property `url: String`, method `send_ipc_message(message: String)`, signal `ipc_message(message: String)`. The class exists even under `--headless`, so guard on the display too.
- `InteractArea.nearest(from: Node3D, max_range: float) -> InteractArea` (`lib/components/InteractArea.gd`), field `prompt`. Range `GameConst.INTERACT_RANGE`.
- `PlayerRoleController.LifeState.{ALIVE, DOWNED, DEAD}`.
- Test rule (`AGENTS.md`): free test nodes before asserting. Tests extend `TestCase` (`assert_true`, `assert_false`, `assert_eq`).

## IPC protocol (copy exactly)
All messages are JSON strings (`JSON.stringify` / `JSON.parse_string`).
- Godot -> page: `{"type":"hud","data":HudState}`, `{"type":"route","to":"/"}`, `{"type":"reply","id":<int>,"ok":<bool>,"data":<any>}` or `{"type":"reply","id":<int>,"ok":false,"error":"<text>"}`.
- Page -> Godot: `{"type":"ready"}`, `{"type":"request","id":<int>,"method":"<name>","params":{}}`.
- `HudState` keys: `role` (String), `life` (String), `cash` (int), `bag` (int), `notoriety` (int), `timer` (`{"label": String, "seconds": int}` or `null`), `prompt` (String), `notifications` (Array of String).
- Methods: only `ping` -> reply `ok: true`, `data: {"pong": true}`. Anything else -> `ok: false`, `error: "unknown_method"`.

## Files
- modify: `lib/constants/GameConst.gd`
- modify: `ui/hud/Hud.gd`
- modify: `tests/ui/hud/test_hud.gd`

## Steps
1. `lib/constants/GameConst.gd`, in the `# HUD` block add:
   ```gdscript
   const UI_PAGE_URL: String = "res://ui/web/index.html"  # built web UI (webui/ -> ui/web/)
   const UI_DEV_URL: String = "http://localhost:5173/"     # Vite dev server
   const UI_DEV_FLAG: String = "--ui-dev"                  # client user arg: load UI_DEV_URL
   ```
   Remove `HUD_MARGIN` and `HUD_FONT_SIZE` (no longer used; check with a search first and keep them if anything else uses them).
2. `ui/hud/Hud.gd`: replace the Label code with a browser bridge. Keep `class_name Hud extends CanvasLayer` and the doc comment idea ("Main feeds it the local player and ServerManager events; it never talks to the network"), add "Draws the web UI (docs/design/WEB_UI.md) in a CefTexture."
   - Remove `money_text`, `_make_label` and all `*_label` vars.
   - Add pure static helpers:
     ```gdscript
     ## True only on a client with a real display and the CEF addon loaded.
     static func can_use_browser() -> bool:
         return DisplayServer.get_name() != "headless" and ClassDB.class_exists("CefTexture")

     ## Built page, or the Vite dev server when the client got `-- --ui-dev`.
     static func page_url(user_args: PackedStringArray) -> String:
         return GameConst.UI_DEV_URL if user_args.has(GameConst.UI_DEV_FLAG) else GameConst.UI_PAGE_URL

     ## HudState for the page. `prompt` shows only while ALIVE.
     static func snapshot(role: int, life: int, downed_deadline_ms: int, mask_end_ms: int,
             money: Dictionary, prompt: String, notifications: Array, now_ms: int) -> Dictionary:

     ## Reply to one page request.
     static func reply_for(request: Dictionary) -> Dictionary:
     ```
     `snapshot` returns `{"role": role_text(role), "life": life_text(life), "cash": int(money.get("cash", 0)), "bag": int(money.get("bag_value", 0)), "notoriety": int(money.get("notoriety", 0)), "timer": <timer>, "prompt": prompt if life == ALIVE else "", "notifications": <texts>}`. `<timer>`: when `life == DOWNED` -> `{"label": "Bleeding out", "seconds": seconds_left(downed_deadline_ms, now_ms)}`; elif `mask_end_ms > now_ms` -> `{"label": "Masking", "seconds": seconds_left(mask_end_ms, now_ms)}`; else `null`. `<texts>`: `String(entry.get("text", ""))` of each entry, in order.
     `reply_for`: `var id := int(request.get("id", 0))`; method `"ping"` -> `{"type": "reply", "id": id, "ok": true, "data": {"pong": true}}`; else `{"type": "reply", "id": id, "ok": false, "error": "unknown_method"}`.
   - Instance vars: keep `_player`, `_money`, `_mask_end_ms`, `_notifications`; add `var _browser: Control = null`, `var _page_ready: bool = false`, `var _last_hud_json: String = ""`.
   - `_ready()`: return if `not can_use_browser()`. Else:
     ```gdscript
     _browser = ClassDB.instantiate("CefTexture") as Control
     _browser.name = "Browser"
     _browser.set("url", page_url(OS.get_cmdline_user_args()))
     _browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
     _browser.mouse_filter = Control.MOUSE_FILTER_IGNORE
     _browser.focus_mode = Control.FOCUS_NONE
     _browser.connect("ipc_message", _on_ipc_message)
     add_child(_browser)
     ```
   - Keep the four public methods unchanged.
   - `_process(_delta)`:
     1. `var now_ms := int(Time.get_unix_time_from_system() * 1000.0)`; `_notifications = prune_notifications(_notifications, now_ms)`.
     2. Return if `not _page_ready`.
     3. If `_player` is valid: read `role`, `life_state`, `downed_deadline_ms` with `_player.get(...)`, and the prompt from `InteractArea.nearest(_player, GameConst.INTERACT_RANGE)` (`area.prompt` or `""`). If not valid: role `-1`, life `-1`, deadline `0`, prompt `""`.
     4. `var json := JSON.stringify({"type": "hud", "data": snapshot(...)})`; if `json != _last_hud_json`: `_last_hud_json = json` and `_send_json(json)`.
   - `func _on_ipc_message(message: String) -> void`: `var parsed: Variant = JSON.parse_string(message)`; return unless `parsed is Dictionary`. `type == "ready"` -> `_page_ready = true`, `_last_hud_json = ""` (forces a resend next frame), `_send_json(JSON.stringify({"type": "route", "to": "/"}))`. `type == "request"` -> `_send_json(JSON.stringify(reply_for(parsed)))`. Anything else: ignore.
   - `func _send_json(json: String) -> void`: if `_browser != null and is_instance_valid(_browser)`: `_browser.call("send_ipc_message", json)`.
3. `tests/ui/hud/test_hud.gd`:
   - Keep `test_role_and_life_text`, `test_seconds_left`, `test_notifications_trim_and_expire`.
   - Delete `test_money_text` and `test_hud_builds_labels`.
   - Add (use `const ALIVE := PlayerRoleController.LifeState.ALIVE`, `DOWNED := ...DOWNED`, `CRIMINAL := PlayerRoleController.Role.CRIMINAL`):
     - `test_snapshot_money_and_role`: `Hud.snapshot(CRIMINAL, ALIVE, 0, 0, {"cash": 50, "bag_value": 500, "notoriety": 500.0}, "", [], 1000)` has `role "CRIMINAL"`, `life "ALIVE"`, `cash 50`, `bag 500`, `notoriety 500`, `timer == null`.
     - `test_snapshot_bleed_out_timer`: life DOWNED, deadline `10000`, now `7500` -> `timer == {"label": "Bleeding out", "seconds": 3}`.
     - `test_snapshot_mask_timer`: life ALIVE, mask_end `5000`, now `3500` -> `timer == {"label": "Masking", "seconds": 2}`.
     - `test_snapshot_prompt_only_when_alive`: prompt `"E lockpick"` gives `"E lockpick"` when ALIVE and `""` when DOWNED.
     - `test_snapshot_notification_texts`: notifications `[{"text": "a", "expires_ms": 9}, {"text": "b", "expires_ms": 9}]` -> `["a", "b"]`.
     - `test_reply_ping`: `Hud.reply_for({"type": "request", "id": 7, "method": "ping"})` equals `{"type": "reply", "id": 7, "ok": true, "data": {"pong": true}}`.
     - `test_reply_unknown_method`: method `"nope"`, id 8 -> `ok false`, `error "unknown_method"`, `id 8`.
     - `test_page_url`: `Hud.page_url(PackedStringArray())` is `GameConst.UI_PAGE_URL`; `Hud.page_url(PackedStringArray(["--ui-dev"]))` is `GameConst.UI_DEV_URL`.
     - `test_headless_has_no_browser`: `var hud := Hud.new()`; `(Engine.get_main_loop() as SceneTree).root.add_child(hud)`; `var count := hud.get_child_count()`; `hud.free()`; assert `count == 0` and `Hud.can_use_browser() == false` (tests run headless).

## Do not
- Do not touch `main/Main.gd`, `webui/`, `ui/web/`, or any server code. No new RPCs. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` warning lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
