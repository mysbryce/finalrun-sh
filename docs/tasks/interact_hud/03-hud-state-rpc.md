# interact_hud 03: owner-only HUD state and mask channel RPCs

Roadmap: Phase 2, "basic HUD (role, mask timer, bag value)", server side. Cash, bag and notoriety are server-only today, and the mask channel start/stop never reaches the client. This card sends them to the owning client only. Card 04 draws them.

## Context (already true, do not change)
- `PlayerRoleController` (`features/player/PlayerRoleController.gd`) signals: `role_changed(old_role: int, new_role: int)`, `mask_channel_started(duration_seconds: float)`, `mask_channel_cancelled(reason: String)`, `inventory_changed`. Fields `cash: int`, `notoriety: float`; `loot_value() -> int` sums the bag.
- A successful mask does not emit `mask_channel_cancelled`; it changes the role to CRIMINAL (`role_changed`).
- `PlayerService.spawn_node(data)` (`features/player/PlayerService.gd` ~line 175), server branch: after `player.call("setup_server", instance, state)` it does `controller.life_state_changed.connect(_on_player_life_state_changed.bind(player))`. The new player is not in the tree yet at that point, so `get_controller(peer_id)` would return null there: bind the controller itself.
- `PlayerService._host` is the ServerManager node. `ServerManager._send_client_rpc(peer_id, method, args)` sends an RPC on ServerManager to one peer. PlayerService already calls host methods with `_host.call("_notify", peer_id, text)`.
- ServerManager client RPC pattern:
  ```gdscript
  @rpc("authority", "call_remote", "reliable")
  func client_message(text: String) -> void:
      print("[FinalRun] %s" % text)
      notification_received.emit(text)
  ```
  Signals are declared at the top of `autoload/ServerManager.gd` (`signal notification_received(text: String)` ...).
- Gameplay data goes only to the owning peer (never a broadcast `rpc()`).

## Files
- modify: `features/player/PlayerService.gd`
- modify: `autoload/ServerManager.gd`
- create: `tests/features/player/test_hud_state.gd`

## Steps
1. `autoload/ServerManager.gd`:
   - Add signals under the existing ones:
     `signal hud_state_received(state: Dictionary)` and `signal mask_channel_received(seconds: float)`.
   - Add next to `client_message`:
     ```gdscript
     ## Owner-only HUD numbers: {"cash": int, "bag_value": int, "notoriety": float}.
     @rpc("authority", "call_remote", "reliable")
     func client_hud_state(state: Dictionary) -> void:
         hud_state_received.emit(state)


     ## Owner-only mask channel: seconds > 0 started, 0 ended or cancelled.
     @rpc("authority", "call_remote", "reliable")
     func client_mask_channel(seconds: float) -> void:
         mask_channel_received.emit(seconds)
     ```
2. `features/player/PlayerService.gd`:
   - Add a pure static helper:
     ```gdscript
     ## HUD numbers the owning client may see.
     static func hud_state_of(controller: PlayerRoleController) -> Dictionary:
         return {
             "cash": controller.cash,
             "bag_value": controller.loot_value(),
             "notoriety": controller.notoriety,
         }
     ```
   - Add private senders/handlers (signal args first, bound args last):
     ```gdscript
     func _send_hud_state(peer_id: int, controller: PlayerRoleController) -> void:
         if is_instance_valid(controller):
             _host.call("_send_client_rpc", peer_id, "client_hud_state", [hud_state_of(controller)])

     func _send_mask_channel(peer_id: int, seconds: float) -> void:
         _host.call("_send_client_rpc", peer_id, "client_mask_channel", [seconds])

     func _on_hud_inventory_changed(peer_id: int, controller: PlayerRoleController) -> void:
         _send_hud_state(peer_id, controller)

     func _on_hud_role_changed(_old_role: int, _new_role: int, peer_id: int, controller: PlayerRoleController) -> void:
         _send_mask_channel(peer_id, 0.0)
         _send_hud_state(peer_id, controller)

     func _on_hud_mask_started(duration_seconds: float, peer_id: int) -> void:
         _send_mask_channel(peer_id, duration_seconds)

     func _on_hud_mask_cancelled(_reason: String, peer_id: int) -> void:
         _send_mask_channel(peer_id, 0.0)
     ```
   - In `spawn_node`, server branch, inside the existing `if controller != null:` block right after the `life_state_changed.connect(...)` line, add:
     ```gdscript
     controller.inventory_changed.connect(_on_hud_inventory_changed.bind(peer_id, controller))
     controller.role_changed.connect(_on_hud_role_changed.bind(peer_id, controller))
     controller.mask_channel_started.connect(_on_hud_mask_started.bind(peer_id))
     controller.mask_channel_cancelled.connect(_on_hud_mask_cancelled.bind(peer_id))
     _send_hud_state(peer_id, controller)
     ```
3. Create `tests/features/player/test_hud_state.gd` (`extends TestCase`, `const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")`):
   - `test_hud_state_empty`: new controller; `var state := PlayerService.hud_state_of(controller)`; `controller.free()`; assert `state["cash"] == 0`, `state["bag_value"] == 0`, `state["notoriety"] == 0.0`.
   - `test_hud_state_counts_bag_and_cash`: new controller; `grant_loot("jewelry", 300)`; `grant_loot("cash_box", 200)`; `controller.cash = 50`; take the state; `controller.free()`; assert `cash == 50`, `bag_value == 500`, `notoriety == 500.0`.
   - `test_hud_state_has_only_owner_fields`: state keys sorted equal `["bag_value", "cash", "notoriety"]` (free the controller before asserting).

## Do not
- Do not add UI or touch `main/Main.gd`. Do not broadcast. Do not touch files outside the list. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
