# interact_hud 02: loot crates in LootyBay through InteractArea (lockpick = E, smash = V)

Roadmap: Phase 2 interact system. Needs card 01 (`InteractArea` in `lib/components/InteractArea.gd`, `InteractArea.nearest(from, max_range)`). Lockpick stays instant here; the lockpick channel and the big heist come in Phase 3.

## Context (already true, do not change)
- `features/heist/Lootable.gd` (`class_name Lootable extends Node3D`): exports `loot_id`, `value`, `locked`; `var looted`; `server_lockpick(player)` (silent), `server_smash(player)` (loud: `_broadcast_loud_alert()`), private `_can_be_looted_by(player)`, `_grant_to(player)`, `_find_instance()`. It already preloads `RoleControllerScript`. Nothing calls it yet and no map places one.
- `PlayerRoleController` (`features/player/PlayerRoleController.gd`): `role`, `life_state`, enums `Role.{CITIZEN, CRIMINAL, COP}` and `LifeState.{ALIVE, DOWNED, DEAD}`.
- `GameInstance` (`features/instance/Instance.gd`): `map_root: Node3D` (the instantiated map), `rpc_to_members(callable_name, args, only_peers := [])`, `rpc_to_specific_members(callable_name, args, peers)`, `sync_state_to_peer(peer_id)` (~line 251) replays world state to a late joiner. Client RPC example in the same file:
  ```gdscript
  @rpc("authority", "call_remote", "reliable")
  func client_set_police_vehicle(active: bool) -> void:
  ```
- `ServerManager` RPC pattern (`autoload/ServerManager.gd`):
  ```gdscript
  @rpc("any_peer", "call_remote", "reliable")
  func server_request_mask() -> void:
      var sender: int = multiplayer.get_remote_sender_id()
      if _can_accept_alive_request(sender):
          _players.mask(sender)
  ```
  and client facades near line 314: `func request_mask() -> void: _send_client_request("server_request_mask")`.
- `PlayerService.fire(...)` (`features/player/PlayerService.gd`) shows the lookup order: `_transfers.has_transfer(peer_id)`, `_instances.current_instance_for_peer(peer_id)`, `instance.get_player(peer_id) as PlayerCharacter`. `_notify(peer_id, text)` sends a message to that client.
- `GameConst.INTERACT_RANGE` = 2.5 m already exists.
- `main/Main.gd` `_unhandled_input` has a `match key_event.physical_keycode:` with a `KEY_E:` branch (body search) and a helper `_local_player() -> PlayerCharacter`.
- Test rule from `AGENTS.md`: free test nodes before asserting.

## Files
- modify: `features/heist/Lootable.gd`
- modify: `features/instance/Instance.gd`
- modify: `features/player/PlayerService.gd`
- modify: `autoload/ServerManager.gd`
- modify: `maps/looty_bay/LootyBay.tscn`
- modify: `main/Main.gd`
- create: `tests/features/heist/test_lootable.gd`

## Steps
1. `features/heist/Lootable.gd`:
   - Add pure static rules:
     ```gdscript
     ## Only an ALIVE CRIMINAL may loot (mask first).
     static func role_may_loot(role: int, life_state: int) -> bool:
         return role == RoleControllerScript.Role.CRIMINAL and life_state == RoleControllerScript.LifeState.ALIVE

     ## A client-sent lootable name must be one plain node name (no path parts).
     static func is_valid_lootable_name(lootable_name: String) -> bool:
         return not lootable_name.is_empty() and lootable_name.validate_node_name() == lootable_name

     ## Finds `<map_root>/Lootables/<lootable_name>`, or null.
     static func find_in(map_root: Node, lootable_name: String) -> Lootable:
     ```
     `find_in`: return null if `map_root` is null or not valid, or `not is_valid_lootable_name(lootable_name)`; else `return map_root.get_node_or_null(NodePath("Lootables/" + lootable_name)) as Lootable`.
   - Add `func mark_looted() -> void`: `looted = true`, `visible = false`, `set_process(false)`.
   - In `_can_be_looted_by(player)`: replace the final `if player.get_node_or_null("PlayerRoleController") == null: return false` / `return true` with:
     ```gdscript
     var controller := player.get_node_or_null("PlayerRoleController") as PlayerRoleController
     if controller == null:
         return false
     return role_may_loot(controller.role, controller.life_state)
     ```
   - In `_grant_to(player)`: replace `looted = true`, `visible = false`, `set_process(false)` with `mark_looted()`. After it, tell clients:
     ```gdscript
     var instance := _find_instance()
     if instance != null:
         instance.call("rpc_to_members", "client_lootable_looted", [String(name)])
     ```
     Keep the `grant_loot` call.
2. `features/instance/Instance.gd`:
   - In the client-bound RPC section add:
     ```gdscript
     @rpc("authority", "call_remote", "reliable")
     func client_lootable_looted(lootable_name: String) -> void:
         var lootable := Lootable.find_in(map_root, lootable_name)
         if lootable != null:
             lootable.mark_looted()
     ```
   - In `sync_state_to_peer(peer_id)`, right after the `client_set_police_vehicle` line and before `if drops_root == null:`, add: get `map_root.get_node_or_null("Lootables")` (skip if `map_root` or that node is null); for each child that is a `Lootable` with `looted == true`, call `rpc_to_specific_members("client_lootable_looted", [String(child.name)], peers)`.
3. `features/player/PlayerService.gd`, add after `fire(...)`:
   ```gdscript
   ## Server-validated loot action on a map Lootable. smash=false is the silent
   ## lockpick, smash=true is loud and alerts COP and CRIMINAL members.
   func loot(peer_id: int, lootable_name: String, smash: bool) -> void:
   ```
   In this order:
   1. Return if `_transfers.has_transfer(peer_id)`.
   2. `var instance := _instances.current_instance_for_peer(peer_id)`; return if null.
   3. `var player := instance.get_player(peer_id) as PlayerCharacter`; return if null.
   4. `var lootable := Lootable.find_in(instance.map_root, lootable_name)`; return if null.
   5. If `lootable.looted`: `_notify(peer_id, "Already looted")` and return.
   6. If `player.global_position.distance_to(lootable.global_position) > GameConst.INTERACT_RANGE`: `_notify(peer_id, "Too far away")` and return.
   7. `var value: int = lootable.value`; `var ok: bool = lootable.server_smash(player) if smash else lootable.server_lockpick(player)`.
   8. If `ok`: `_notify(peer_id, "Looted $%d (%s)" % [value, "loud" if smash else "silent"])`; else `_notify(peer_id, "Only an ALIVE CRIMINAL can loot (mask first)")`.
4. `autoload/ServerManager.gd`:
   - Add next to `server_request_fire`:
     ```gdscript
     @rpc("any_peer", "call_remote", "reliable")
     func server_request_loot(lootable_name: String, smash: bool) -> void:
         var sender: int = multiplayer.get_remote_sender_id()
         if _can_accept_alive_request(sender):
             _players.loot(sender, lootable_name, smash)
     ```
   - Add facade after `request_fire`: `func request_loot(lootable_name: String, smash: bool) -> void: _send_client_request("server_request_loot", [lootable_name, smash])`.
5. `maps/looty_bay/LootyBay.tscn`:
   - Add two ext_resources right after the `[gd_scene ...]` header line (blank line between blocks):
     `[ext_resource type="Script" path="res://features/heist/Lootable.gd" id="1_lootable"]`
     `[ext_resource type="Script" path="res://lib/components/InteractArea.gd" id="2_interact"]`
   - Add two sub_resources after the last existing sub_resource (`StandardMaterial3D_police_car`):
     `[sub_resource type="BoxMesh" id="BoxMesh_crate"]` with `size = Vector3(0.8, 0.8, 0.8)`;
     `[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_crate"]` with `albedo_color = Color(0.85, 0.65, 0.2, 1)`.
   - Raise `load_steps` in the header by 4.
   - Append at the end of the file a `Lootables` Node3D (parent ".") with three crates. Each crate is a `Node3D` with `script = ExtResource("1_lootable")`, and two children: `Mesh` (`MeshInstance3D`, `mesh = SubResource("BoxMesh_crate")`, `surface_material_override/0 = SubResource("StandardMaterial3D_crate")`) and `InteractArea` (`Node3D`, `script = ExtResource("2_interact")`, `prompt = "E lockpick | V smash"`).
     | Node | position (transform origin) | loot_id | value |
     |---|---|---|---|
     | `Crate01` | `-16, 0.4, -10` | `"jewelry"` | `300` |
     | `Crate02` | `-4, 0.4, -16` | `"electronics"` | `500` |
     | `Crate03` | `12, 0.4, -10` | `"cash_box"` | `800` |
     Use `transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z)` like the other nodes. No collision bodies.
6. `main/Main.gd`:
   - Add a helper:
     ```gdscript
     ## Lootable under the nearest InteractArea in reach, or null.
     func _nearest_lootable() -> Lootable:
         var area := InteractArea.nearest(_local_player(), GameConst.INTERACT_RANGE)
         if area == null:
             return null
         return area.get_parent() as Lootable
     ```
   - In the `KEY_E:` branch, first: `var lootable := _nearest_lootable()`; if not null, `ServerManager.request_loot(String(lootable.name), false)`; otherwise run the existing search code unchanged (wrap it in `else:`).
   - Add a `KEY_V:` branch: `var smash_target := _nearest_lootable()`; if not null `ServerManager.request_loot(String(smash_target.name), true)`, else `print("[Main] Nothing to smash")`.
   - In the controls `print` in `_start_client()`, replace `"E search"` with `"E lockpick/search | V smash"`.
7. Create `tests/features/heist/test_lootable.gd` (`extends TestCase`, `const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")`):
   - `test_criminal_alive_may_loot`: `Lootable.role_may_loot(CRIMINAL, ALIVE)` is true.
   - `test_citizen_and_cop_may_not_loot`: `(CITIZEN, ALIVE)` and `(COP, ALIVE)` are false.
   - `test_downed_criminal_may_not_loot`: `(CRIMINAL, DOWNED)` is false.
   - `test_lootable_name_validation`: `"Crate01"` true; `""`, `"../Map"`, `"Lootables/Crate01"` false.
   - `test_looty_bay_has_crates`: `var root := (load("res://maps/looty_bay/LootyBay.tscn") as PackedScene).instantiate()`; store plain values (bools/ints, not node references) before freeing: `has_crate := crate != null`, `crate_value := crate.value if has_crate else -1`, `has_area := has_crate and crate.get_node_or_null("InteractArea") is InteractArea`, `bad_lookup_null := Lootable.find_in(root, "../LootyBay") == null`; then `root.free()`; then assert `has_crate`, `crate_value == 300`, `has_area`, `bad_lookup_null`.

## Do not
- Do not add channels, timers, HUD, or collision. Do not change `server_lockpick`/`server_smash` signatures or `_broadcast_loud_alert`. Do not touch files outside the list. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
