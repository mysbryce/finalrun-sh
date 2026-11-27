# interact_hud 04: basic client HUD (role, life, bleed-out, mask timer, money, prompt, notifications)

Roadmap: Phase 2, "basic HUD (role, mask timer, bag value)", client side. Needs card 02 (`InteractArea` on loot crates) and card 03 (`ServerManager.hud_state_received`, `mask_channel_received`).

## Context (already true, do not change)
- Dependency direction (`docs/CONVENTIONS.md`): `main/ -> autoload/ -> features/ -> lib/`, and `ui/ -> features/, lib/`. So `ui/` must NOT reference `ServerManager`. `Main.gd` connects the ServerManager signals to the HUD methods.
- `ui/` holds client UI scenes and scripts. Script files are `PascalCase.gd` with a matching `class_name`.
- Player (`features/player/Player.gd`, `class_name PlayerCharacter`) replicates `role: int`, `life_state: int`, `downed_deadline_ms: int` (unix ms) to every client. Enums: `PlayerRoleController.Role.{CITIZEN, CRIMINAL, COP}`, `PlayerRoleController.LifeState.{ALIVE, DOWNED, DEAD}`.
- `InteractArea.nearest(from: Node3D, max_range: float) -> InteractArea` (`lib/components/InteractArea.gd`), field `prompt: String`. Range constant `GameConst.INTERACT_RANGE`.
- `ServerManager` signals: `notification_received(text: String)`, `hud_state_received(state: Dictionary)` with keys `cash: int`, `bag_value: int`, `notoriety: float`, and `mask_channel_received(seconds: float)` (> 0 started, 0 ended).
- `main/Main.gd`: `_start_client()` connects ServerManager signals (`ServerManager.search_contents_received.connect(...)`); `_process(_delta)` returns early in server mode, then reads `var player := _local_player()`.
- Client time for the bleed-out: `int(Time.get_unix_time_from_system() * 1000.0)` (same clock as the server deadline).
- Test rule (`AGENTS.md`): free test nodes before asserting.

## Files
- modify: `lib/constants/GameConst.gd`
- create: `ui/hud/Hud.gd`
- modify: `main/Main.gd`
- create: `tests/ui/hud/test_hud.gd`

## Steps
1. `lib/constants/GameConst.gd`: add a `# HUD` block at the end:
   ```gdscript
   # HUD
   const HUD_NOTIFICATION_MS: int = 4000   # how long a notification stays on screen
   const HUD_MAX_NOTIFICATIONS: int = 4    # newest kept, oldest dropped
   const HUD_MARGIN: float = 16.0          # px from the screen edge
   const HUD_FONT_SIZE: int = 18
   ```
2. Create `ui/hud/Hud.gd`: `class_name Hud extends CanvasLayer`, doc comment "Client HUD built in code. Main feeds it the local player and ServerManager events; it never talks to the network."
   - Pure static helpers:
     ```gdscript
     static func role_text(role: int) -> String  # "CITIZEN" / "CRIMINAL" / "COP", else "?"
     static func life_text(life_state: int) -> String  # "ALIVE" / "DOWNED" / "DEAD", else "?"
     static func money_text(state: Dictionary) -> String
         # "Cash $%d | Bag $%d | Notoriety %d" from cash, bag_value, int(notoriety); missing keys count as 0
     static func seconds_left(deadline_ms: int, now_ms: int) -> int
         # ceil((deadline_ms - now_ms) / 1000.0), never below 0
     static func push_notification(list: Array, text: String, now_ms: int) -> Array
         # returns a new array: list + [{"text": text, "expires_ms": now_ms + GameConst.HUD_NOTIFICATION_MS}],
         # trimmed to the newest GameConst.HUD_MAX_NOTIFICATIONS entries
     static func prune_notifications(list: Array, now_ms: int) -> Array
         # returns a new array without entries whose expires_ms <= now_ms
     ```
   - State vars: `var _player: Node3D = null`, `var _money: Dictionary = {}`, `var _mask_end_ms: int = 0`, `var _notifications: Array = []`.
   - Labels built in `_ready()` (each a `Label` with `add_theme_font_size_override("font_size", GameConst.HUD_FONT_SIZE)`), stored in vars:
     - `_status_label` (top-left at `(HUD_MARGIN, HUD_MARGIN)`): role and life.
     - `_money_label` (below it, `y = HUD_MARGIN + 28`).
     - `_timer_label` (below it, `y = HUD_MARGIN + 56`): mask timer or bleed-out.
     - `_notify_label` (top-right): anchors preset `Control.PRESET_TOP_RIGHT`, `horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT`, `grow_horizontal = Control.GROW_DIRECTION_BEGIN`, offset `HUD_MARGIN` from the top and right.
     - `_prompt_label` (bottom-center): anchors preset `Control.PRESET_CENTER_BOTTOM`, `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER`, `grow_horizontal = Control.GROW_DIRECTION_BOTH`, `grow_vertical = Control.GROW_DIRECTION_BEGIN`, bottom offset `-HUD_MARGIN * 4`.
   - Public methods (called by Main):
     - `func set_player(player: Node3D) -> void`: `_player = player`.
     - `func set_money(state: Dictionary) -> void`: `_money = state.duplicate()`.
     - `func set_mask_channel(seconds: float, now_ms: int) -> void`: `_mask_end_ms = now_ms + int(seconds * 1000.0)` when `seconds > 0.0`, else `0`.
     - `func add_notification(text: String, now_ms: int) -> void`: `_notifications = push_notification(_notifications, text, now_ms)`.
   - `func _process(_delta: float) -> void`, with `var now_ms := int(Time.get_unix_time_from_system() * 1000.0)`:
     1. If `_player` is null or not valid: hide status, timer and prompt labels (`text = ""`), still update notifications, return.
     2. `role := int(_player.get("role"))`, `life := int(_player.get("life_state"))`; `_status_label.text = "%s | %s" % [role_text(role), life_text(life)]`.
     3. `_money_label.text = money_text(_money)`.
     4. Timer: if `life == PlayerRoleController.LifeState.DOWNED`: `"Bleeding out: %d s" % seconds_left(int(_player.get("downed_deadline_ms")), now_ms)`; elif `_mask_end_ms > now_ms`: `"Masking: %d s" % seconds_left(_mask_end_ms, now_ms)`; else `""`.
     5. Prompt: `var area := InteractArea.nearest(_player, GameConst.INTERACT_RANGE)`; text is `area.prompt` when `area != null` and `life == ALIVE`, else `""`.
     6. Notifications: `_notifications = prune_notifications(_notifications, now_ms)`; `_notify_label.text` = the `text` of each entry joined with `"\n"`.
3. `main/Main.gd`:
   - Add `var _hud: Hud = null`.
   - In `_start_client()`, after `_create_client_view_container()`: `_hud = Hud.new()`, `_hud.name = "Hud"`, `add_child(_hud)`. After the existing `ServerManager.search_closed_received.connect(...)` line add:
     ```gdscript
     ServerManager.notification_received.connect(_on_hud_notification)
     ServerManager.hud_state_received.connect(_on_hud_state)
     ServerManager.mask_channel_received.connect(_on_hud_mask_channel)
     ```
   - Add handlers:
     ```gdscript
     func _on_hud_notification(text: String) -> void:
         if _hud != null:
             _hud.add_notification(text, _client_now_ms())

     func _on_hud_state(state: Dictionary) -> void:
         if _hud != null:
             _hud.set_money(state)

     func _on_hud_mask_channel(seconds: float) -> void:
         if _hud != null:
             _hud.set_mask_channel(seconds, _client_now_ms())

     func _client_now_ms() -> int:
         return int(Time.get_unix_time_from_system() * 1000.0)
     ```
   - In `_process`, right after `var player := _local_player()` (before its null check), add `if _hud != null: _hud.set_player(player)`.
   - `_create_client_view_container()` must keep the HUD above the 3D view: the HUD is a `CanvasLayer`, so no change is needed there. Do not change it.
4. Create `tests/ui/hud/test_hud.gd` (`extends TestCase`):
   - `test_role_and_life_text`: `Hud.role_text(PlayerRoleController.Role.CRIMINAL) == "CRIMINAL"`, `Hud.role_text(99) == "?"`, `Hud.life_text(PlayerRoleController.LifeState.DOWNED) == "DOWNED"`.
   - `test_money_text`: `Hud.money_text({"cash": 50, "bag_value": 500, "notoriety": 500.0}) == "Cash $50 | Bag $500 | Notoriety 500"`; `Hud.money_text({}) == "Cash $0 | Bag $0 | Notoriety 0"`.
   - `test_seconds_left`: `(10000, 7500) -> 3`, `(10000, 9000) -> 1`, `(10000, 10000) -> 0`, `(10000, 12000) -> 0`.
   - `test_notifications_trim_and_expire`: push 5 texts `"a".."e"` at `now_ms = 0`; size is `GameConst.HUD_MAX_NOTIFICATIONS` and the first entry text is `"b"`; `prune_notifications(list, GameConst.HUD_NOTIFICATION_MS)` is empty; `prune_notifications(list, GameConst.HUD_NOTIFICATION_MS - 1)` has 4 entries.
   - `test_hud_builds_labels`: `var hud := Hud.new()`; `(Engine.get_main_loop() as SceneTree).root.add_child(hud)` (this runs `_ready`, same pattern as `tests/features/heist/test_loot_container.gd`); call `hud.set_player(null)`; read `hud.get_child_count()` into a local; `hud.free()`; assert the count is `5`.

## Do not
- No ServerManager reference inside `ui/`. No new RPCs. No `.tscn` for the HUD. Do not touch files outside the list. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
