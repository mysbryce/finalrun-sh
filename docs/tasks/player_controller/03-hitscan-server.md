# player_controller 03: server-side hitscan fire + safezone weapon lock

Roadmap: Phase 2, "Health, hitscan weapons (server raycast in instance world), safezone weapon lock". Replaces the old target-by-peer-id attack (`K` key) with aim-based firing. Card 04 adds the client mouse input; do not start it.

## Context (already true, do not change)
- `PlayerCharacter.take_damage(amount)` (`features/player/Player.gd`) already handles health, downed and death. Health stays server-only for now (HUD card later).
- `PlayerRoleController.can_attack(target, same_party)` is the role/map/party rule. It already returns false outside LootyBay and in safezones.
- `PlayerService.has_line_of_sight(...)` (`features/player/PlayerService.gd` ~line 513) shows how to raycast in the shooter's own `World3D`: `from_player.get_world_3d().direct_space_state`, `PhysicsRayQueryParameters3D.create(from, to, GameConst.RAYCAST_COLLISION_MASK)`, exclude the shooter's RID.
- `ServerManager` RPC pattern (`autoload/ServerManager.gd`):
  ```gdscript
  @rpc("any_peer", "call_remote", "reliable")
  func server_request_x(...) -> void:
      var sender: int = multiplayer.get_remote_sender_id()
      if _can_accept_alive_request(sender):
          _players.x(sender, ...)
  ```
  and the client facade one-liners `func request_x(...) -> void: _send_client_request("server_request_x", [...])`. `ServerManager._now_ms()` gives unix ms.

## Files
- modify: `lib/constants/GameConst.gd`
- modify: `features/player/PlayerService.gd`
- modify: `autoload/ServerManager.gd`
- modify: `main/Main.gd`
- create: `tests/features/player/test_fire_rules.gd`

## Steps
1. `lib/constants/GameConst.gd`: next to `ATTACK_DAMAGE` add `const FIRE_INTERVAL_MS: int = 250  # minimum time between shots per player`.
2. `features/player/PlayerService.gd`:
   - Add `var _last_fire_ms: Dictionary = {}  # peer_id -> unix ms of the last accepted shot`.
   - Add pure static helpers (near `party_role_conflict`):
     ```gdscript
     ## True when enough time has passed since the last accepted shot.
     static func fire_allowed(now_ms: int, last_fire_ms: int, interval_ms: int) -> bool:
         return now_ms - last_fire_ms >= interval_ms

     ## Normalized aim, or Vector3.ZERO when the client sent garbage.
     static func sanitize_aim(aim: Vector3) -> Vector3:
         if not aim.is_finite() or aim.length_squared() < 0.0001:
             return Vector3.ZERO
         return aim.normalized()
     ```
   - Replace the whole `func attack(peer_id: int, target_peer_id: int)` with `func fire(peer_id: int, aim: Vector3, now_ms: int) -> void`, in this order:
     1. Return if `_transfers.has_transfer(peer_id)`.
     2. `var instance := _instances.current_instance_for_peer(peer_id)`; return if null.
     3. `var attacker := instance.get_player(peer_id) as PlayerCharacter`; return if null.
     4. Return if `not fire_allowed(now_ms, int(_last_fire_ms.get(peer_id, 0)), GameConst.FIRE_INTERVAL_MS)`. Then `_last_fire_ms[peer_id] = now_ms`.
     5. Weapon lock: if `instance.safezone or instance.map_name != GameConst.MAP_LOOTY_BAY`: `_notify(peer_id, "Weapons are locked here")` and return.
     6. `var dir := sanitize_aim(aim)`; return if `dir == Vector3.ZERO`.
     7. Raycast in the attacker's world: `from = attacker.global_position + Vector3(0.0, GameConst.LINE_OF_SIGHT_EYE_HEIGHT, 0.0)`, `to = from + dir * GameConst.ATTACK_RANGE`, mask `GameConst.RAYCAST_COLLISION_MASK`, exclude `[attacker.get_rid()]` (typed `Array[RID]`). Return if the hit is empty.
     8. `var target := hit.get("collider") as PlayerCharacter`; return if null or `instance.get_player(int(target.peer_id)) != target` (must be in the same instance).
     9. Compute `same_party` exactly like the old `attack()` did (`_parties.get_party(peer_id)` and `has_member(target peer id)`). Return if `not attacker.get_role_controller().can_attack(target, same_party)` (also return if the controller is null).
     10. `target.take_damage(GameConst.ATTACK_DAMAGE)`.
   - In `handle_peer_left(peer_id)`, add `_last_fire_ms.erase(peer_id)` (keep everything else as is).
3. `autoload/ServerManager.gd`:
   - Replace `server_request_attack(target_peer_id: int)` with:
     ```gdscript
     @rpc("any_peer", "call_remote", "reliable")
     func server_request_fire(aim: Vector3) -> void:
         var sender: int = multiplayer.get_remote_sender_id()
         if _can_accept_alive_request(sender):
             _players.fire(sender, aim, _now_ms())
     ```
   - Replace the facade line `func request_attack(...)` with `func request_fire(aim: Vector3) -> void: _send_client_request("server_request_fire", [aim])`.
4. `main/Main.gd`:
   - Delete the `KEY_K:` branch in `_unhandled_input`.
   - In the controls `print` in `_start_client()`, replace `"K attack"` with `"LMB fire (mouse captured, Esc frees it)"`.
5. Search the repo for any other use of `request_attack`, `server_request_attack`, or `PlayerService.attack`/`_players.attack` and report them (there should be none left). Do not touch `can_attack` or `can_attack_roles`; they stay.
6. Create `tests/features/player/test_fire_rules.gd` in the style of the other test files:
   - `test_fire_allowed_after_interval`: `PlayerService.fire_allowed(1250, 1000, 250)` is true.
   - `test_fire_blocked_inside_interval`: `PlayerService.fire_allowed(1249, 1000, 250)` is false.
   - `test_fire_allowed_first_shot`: `PlayerService.fire_allowed(1000, 0, 250)` is true.
   - `test_sanitize_aim_normalizes`: `sanitize_aim(Vector3(0, 0, -5))` approx `Vector3(0, 0, -1)` (epsilon 0.001).
   - `test_sanitize_aim_rejects_zero`: `sanitize_aim(Vector3.ZERO) == Vector3.ZERO`.
   - `test_sanitize_aim_rejects_nan`: `sanitize_aim(Vector3(NAN, 0, 1)) == Vector3.ZERO`.
   - `test_sanitize_aim_rejects_inf`: `sanitize_aim(Vector3(INF, 0, 1)) == Vector3.ZERO`.

## Do not
- Do not add client input, camera code, or HUD. Do not change `take_damage`. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the result of the step 5 search, the last 3 lines of the test output, any step you could not do and why.
