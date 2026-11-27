# hud_layout 01: Godot side of HudState v2 (health, heading, interact card, party, hotbar, net)

Design: `docs/design/HUD_LAYOUT.md` ("HudState v2"). Card 02 builds the page in parallel; do not touch `ui/web/` or `ui/dist/`.

## Context (already true)
- `ui/hud/Hud.gd` (`class_name Hud extends CanvasLayer`) builds `HudState` in `static func snapshot(role, life, downed_deadline_ms, mask_end_ms, money, prompt, notifications, now_ms)` and sends it as `{"type":"hud","data":...}` when the JSON changed. Keep `role_text`, `life_text`, `seconds_left`, `push_notification`, `prune_notifications`, `can_use_browser`, `page_url`, `reply_for`, `_ready`, `_on_ipc_message`, `_send_json` and the public `set_player`, `set_money`, `set_mask_channel`, `add_notification` unchanged.
- `ui/` may use `features/` and `lib/` but never `ServerManager` (`docs/CONVENTIONS.md`). `main/Main.gd` wires ServerManager signals to the HUD.
- `features/player/Player.gd` (`class_name PlayerCharacter`): `@export var peer_id`, `role`, `life_state`, `downed_deadline_ms` are replicated by the `MultiplayerSynchronizer` in `features/player/Player.tscn` (`properties/0..5`, ON_CHANGE = `replication_mode = 2`). Line 41: `var health: int = MAX_HEALTH` is server-only today.
- `features/instance/Instance.gd` (`class_name GameInstance`): `get_player(peer_id: int) -> Node` (null when absent).
- `ServerManager.party_changed_client(party_info: Dictionary)`: `{"active": true, "party_id", "leader_id": int, "members": Array[int]}` or `{"active": false, "reason": String}`.
- `lib/components/InteractArea.gd`: `@export var prompt: String = "Interact"`. LootyBay crates (`maps/looty_bay/LootyBay.tscn`, nodes `Lootables/Crate01..03/InteractArea`) use `prompt = "E lockpick | V smash"`.
- Tests extend `TestCase` (`assert_true`, `assert_false`, `assert_eq`); free nodes before asserting.

## Files
- modify: `features/player/Player.gd`, `features/player/Player.tscn`
- modify: `lib/components/InteractArea.gd`, `maps/looty_bay/LootyBay.tscn`
- modify: `lib/constants/GameConst.gd`
- modify: `ui/hud/Hud.gd`, `main/Main.gd`
- modify: `tests/ui/hud/test_hud.gd`, `tests/lib/components/test_interact_area.gd`

## Steps
1. `Player.gd` line 41: `var health: int = MAX_HEALTH` -> `@export var health: int = MAX_HEALTH`.
2. `Player.tscn`: in `SceneReplicationConfig_player`, after the `properties/5/...` lines add
   ```
   properties/6/path = NodePath(".:health")
   properties/6/spawn = true
   properties/6/replication_mode = 2
   ```
3. `InteractArea.gd`: under `prompt` add `## Card title shown above the prompt, e.g. "Loot crate".` and `@export var title: String = ""`. In `LootyBay.tscn` add `title = "Loot crate"` to each of the three `InteractArea` nodes (next to `prompt`).
4. `GameConst.gd` `# HUD` block: add `const HUD_HOTBAR_SLOTS: int = 6  # hotbar slots, keys 1-6`.
5. `Hud.gd`, new pure static helpers (doc comment on each):
   ```gdscript
   ## Compass heading in whole degrees 0..359: 0 = north = -Z, 90 = east = +X.
   static func heading_from_yaw(yaw_rad: float) -> int:
       return posmod(int(round(-rad_to_deg(yaw_rad))), 360)

   ## Interact card from an InteractArea; null when prompt is empty.
   ## "E lockpick | V smash" -> actions [{key E, label lockpick}, {key V, label smash}].
   static func interact_of(title: String, prompt: String) -> Variant:
   ```
   `interact_of`: return `null` if `prompt.strip_edges() == ""`. Else split on `"|"`, `strip_edges()` each part, skip empty parts; `var space := part.find(" ")`; `space < 0` -> `{"key": "", "label": part}`, else `{"key": part.left(space), "label": part.substr(space + 1).strip_edges()}`. Return `{"title": title, "actions": actions}`.
   ```gdscript
   static func player_name(peer_id: int) -> String:  # "Player %d" until a name system exists
   ## One other party member. present = their player node is in our instance.
   static func party_entry(peer_id: int, leader_id: int, present: bool, health: int, life: int) -> Dictionary:
   ```
   `party_entry` returns `{"name": player_name(peer_id), "health": health if present else -1, "maxHealth": GameConst.PLAYER_MAX_HEALTH, "life": life_text(life) if present else "?", "leader": peer_id == leader_id, "away": not present}`.
   ```gdscript
   ## Hotbar slots. ponytail: one weapon exists today, so slot 1 is fixed; build from
   ## equipped items once items are Resources (Phase 3).
   static func hotbar() -> Array:
   ```
   returns an Array of size `GameConst.HUD_HOTBAR_SLOTS`: index 0 `{"label": "Pistol"}`, the rest `null`.
6. `Hud.gd`: replace `snapshot` with `static func snapshot(ctx: Dictionary, now_ms: int) -> Dictionary`. Read with defaults: `role` (-1), `life` (-1), `health` (0), `downed_deadline_ms` (0), `mask_end_ms` (0), `money` ({}), `interact_title` (""), `interact_prompt` (""), `notifications` ([]), `heading` (0), `self_id` (0), `party` ([]), `fps` (0), `ping` (0). Return exactly:
   ```gdscript
   {
       "role": role_text(role), "life": life_text(life),
       "health": health, "maxHealth": GameConst.PLAYER_MAX_HEALTH,
       "cash": int(money.get("cash", 0)), "bag": int(money.get("bag_value", 0)),
       "notoriety": int(money.get("notoriety", 0)),
       "heading": heading,
       "timer": <same rule as today: DOWNED -> Bleeding out, elif mask_end_ms > now_ms -> Masking, else null>,
       "interact": interact_of(interact_title, interact_prompt) if life == ALIVE else null,
       "notifications": <texts of the entries, in order>,
       "self": {"name": player_name(self_id)},
       "party": party,
       "hotbar": hotbar(), "activeSlot": 0,
       "net": {"fps": fps, "ping": ping},
   }
   ```
7. `Hud.gd` state and public methods (add, keep the old ones):
   - vars `_instance: GameInstance = null`, `_party_members: Array[int] = []`, `_party_leader: int = 0`, `_fps: int = 0`, `_ping: int = 0`.
   - `func set_instance(instance: GameInstance) -> void`: store it.
   - `func set_party(info: Dictionary) -> void`: when `bool(info.get("active", false))`: `_party_leader = int(info.get("leader_id", 0))`, `_party_members` = each `int(m)` of `info.get("members", [])`; else clear both (`[]`, `0`).
   - `func set_net(fps: int, ping_ms: int) -> void`: store both.
8. `Hud._process`: after the `_page_ready` return, build `ctx` (start `{"money": _money, "mask_end_ms": _mask_end_ms, "notifications": _notifications, "fps": _fps, "ping": _ping}`). When `_player` is valid add: `role`, `life` (`life_state`), `health`, `downed_deadline_ms` (all via `int(_player.get(...))`), `self_id` (`int(_player.get("peer_id"))`); the nearest `InteractArea.nearest(_player, GameConst.INTERACT_RANGE)` -> `interact_title` = `area.title`, `interact_prompt` = `area.prompt`; `var camera := _player.get_viewport().get_camera_3d()`, if not null `heading` = `heading_from_yaw(camera.global_rotation.y)`. `party`: for each `member` in `_party_members` except `self_id`: `var node: Node = _instance.get_player(member) if _instance != null and is_instance_valid(_instance) else null`; `present := node != null`; append `party_entry(member, _party_leader, present, int(node.get("health")) if present else -1, int(node.get("life_state")) if present else -1)`. Then `json := JSON.stringify({"type": "hud", "data": snapshot(ctx, now_ms)})` and the existing send-if-changed.
9. `main/Main.gd`:
   - `_start_client()`: after the `ServerManager.mask_channel_received.connect(...)` line add `ServerManager.party_changed_client.connect(_on_hud_party)`.
   - Add `func _on_hud_party(info: Dictionary) -> void: if _hud != null: _hud.set_party(info)`.
   - Add `var _next_net_ms: int = 0`. In `_process`, inside the existing `if _hud != null:` block after `_hud.set_player(player)`, add `_hud.set_instance(_current_instance())` and: `var ticks := Time.get_ticks_msec()`; `if ticks >= _next_net_ms:` `_next_net_ms = ticks + 1000` and `_hud.set_net(int(Engine.get_frames_per_second()), _client_ping_ms())`.
   - Add:
     ```gdscript
     ## Round-trip time to the server in ms, 0 when unknown.
     func _client_ping_ms() -> int:
         var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
         if enet == null:
             return 0
         var server := enet.get_peer(1)
         if server == null:
             return 0
         return int(server.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
     ```
10. `tests/ui/hud/test_hud.gd`: keep `test_role_and_life_text`, `test_seconds_left`, `test_notifications_trim_and_expire`, `test_reply_ping`, `test_reply_unknown_method`, `test_page_url`, `test_headless_has_no_browser`. Rewrite the five `test_snapshot_*` tests for `snapshot(ctx, now_ms)` with the same expectations (e.g. `Hud.snapshot({"role": CRIMINAL, "life": ALIVE, "money": {"cash": 50, "bag_value": 500, "notoriety": 500.0}}, 1000)`), except the prompt test becomes `test_snapshot_interact_only_when_alive`: ctx with `interact_title "Loot crate"`, `interact_prompt "E lockpick"` gives `interact == {"title": "Loot crate", "actions": [{"key": "E", "label": "lockpick"}]}` when ALIVE and `null` when DOWNED. Add:
    - `test_heading_from_yaw`: `0.0 -> 0`, `-PI / 2 -> 90`, `PI -> 180`, `PI / 2 -> 270`.
    - `test_interact_of`: `("", "")` -> null; `("Loot crate", "E lockpick | V smash")` -> two actions `E/lockpick`, `V/smash`; `("", "Interact")` -> one action `{"key": "", "label": "Interact"}`.
    - `test_party_entry`: present `(3, 3, true, 75, ALIVE)` -> name `"Player 3"`, health 75, life `"ALIVE"`, leader true, away false; absent `(4, 3, false, -1, -1)` -> health -1, life `"?"`, leader false, away true.
    - `test_snapshot_v2_fields`: `snapshot({"health": 75, "heading": 312, "self_id": 2, "fps": 60, "ping": 40}, 0)` has `health 75`, `maxHealth GameConst.PLAYER_MAX_HEALTH`, `heading 312`, `self == {"name": "Player 2"}`, `party == []`, `hotbar.size() == GameConst.HUD_HOTBAR_SLOTS`, `hotbar[0] == {"label": "Pistol"}`, `hotbar[1] == null`, `activeSlot 0`, `net == {"fps": 60, "ping": 40}`.
    - `test_player_replicates_health`: `var scene := load("res://features/player/Player.tscn") as PackedScene`; `var player := scene.instantiate()`; `var sync := player.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer`; read `var config := sync.replication_config`, `var has := config.has_property(NodePath(".:health"))`, `var mode := config.property_get_replication_mode(NodePath(".:health")) if has else -1`; `player.free()`; assert `has` and `mode == SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE`.
11. `tests/lib/components/test_interact_area.gd`: add `test_title_defaults_empty`: `var area := InteractArea.new()`; read `area.title` into a local; `area.free()`; assert it is `""`.

## Do not
- Do not touch `ui/web/`, `ui/dist/`, server RPCs or `PlayerService`. No name system. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
