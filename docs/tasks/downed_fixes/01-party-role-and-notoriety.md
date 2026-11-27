# downed_fixes 01: block mixed COP/CRIMINAL parties, gear removal keeps notoriety, ON_CHANGE replication

Fixes from the downed-state review. Four small, independent fixes.

## Context (already true, do not change)
- `PlayerService.party_role_conflict(member_roles: Array, requested_role: int) -> bool` (`features/player/PlayerService.gd` ~line 336) is the pure party role rule. Keep it as is.
- `PlayerService._party_roles(peer_id) -> Array` (~line 586) returns the roles of the peer's party members (or `[own role]` when the peer has no party).
- `PlayerRoleController.is_mask_channel_active() -> bool` is true while a CITIZEN holds the 3 s mask channel.
- Bug A: a CITIZEN starts masking, a party member goes on cop duty during the 3 s, then the mask completes. The party now has a COP and a CRIMINAL.
- Bug B: `server_request_party_invite` / `server_request_party_accept` (`autoload/ServerManager.gd` ~lines 139-155) never check roles, so a CRIMINAL can invite a COP.

## Files
- modify: `features/player/PlayerService.gd`
- modify: `autoload/ServerManager.gd`
- modify: `features/player/PlayerRoleController.gd`
- modify: `features/player/Player.tscn`
- modify: `tests/features/player/test_items.gd`
- create: `tests/features/party/test_party_roles.gd`

## Steps
1. `features/player/PlayerService.gd`:
   - Add a private helper next to `_party_roles`:
     ```gdscript
     ## A CITIZEN holding the mask channel counts as CRIMINAL for party rules.
     func _effective_role(controller: PlayerRoleController) -> int:
         if controller.is_mask_channel_active():
             return RoleControllerScript.Role.CRIMINAL
         return controller.role
     ```
   - In `_party_roles`, replace both `own_controller.role` and `controller.role` with `_effective_role(own_controller)` / `_effective_role(controller)`. Leave the `_states` fallback branch unchanged.
   - Add a pure static helper next to `party_role_conflict`:
     ```gdscript
     ## True when joining two role sets would put a COP and a CRIMINAL together.
     static func parties_role_conflict(roles_a: Array, roles_b: Array) -> bool:
         var cop := RoleControllerScript.Role.COP
         var criminal := RoleControllerScript.Role.CRIMINAL
         return (roles_a.has(cop) and roles_b.has(criminal)) or (roles_a.has(criminal) and roles_b.has(cop))
     ```
   - Add a public method (near `get_controller`):
     ```gdscript
     ## Party rule for invite/accept: the two sides may not mix COP and CRIMINAL.
     func can_party_together(peer_a: int, peer_b: int) -> bool:
         return not parties_role_conflict(_party_roles(peer_a), _party_roles(peer_b))
     ```
2. `autoload/ServerManager.gd`:
   - In `server_request_party_invite`, after the `_can_accept_alive_request` gate and before `_parties.invite_to_party(...)`, add:
     ```gdscript
     if not _players.can_party_together(sender, target_peer_id):
         _notify(sender, "A party cannot mix COP and CRIMINAL")
         return
     ```
   - In `server_request_party_accept`, after the gate and before `_parties.accept_party_invite(...)`, add the same block with `inviter_peer_id` instead of `target_peer_id`.
   - Do not change `PartyService.gd`.
3. `features/player/PlayerRoleController.gd`, in `remove_item_by_uid(uid)`: lower notoriety only when the item came out of `loot_bag`. Gear removal must not change notoriety. Shape:
   ```gdscript
   var removed: Dictionary = ItemUtils.remove_by_uid(loot_bag, uid)
   var from_bag := not removed.is_empty()
   if not from_bag:
       removed = ItemUtils.remove_by_uid(equipped_gear, uid)
   if removed.is_empty():
       return {}
   if from_bag:
       notoriety = maxf(notoriety - float(int(removed.get("value", 0))), 0.0)
   inventory_changed.emit()
   return removed
   ```
   Update its doc comment: "The victim's notoriety falls by the value of a removed bag item (clamped at 0); gear removal leaves notoriety unchanged."
4. `features/player/Player.tscn`, in the `SceneReplicationConfig` sub-resource: set `replication_mode = 2` (ON_CHANGE) for `properties/1` (`.:role`), `properties/4` (`.:life_state`) and `properties/5` (`.:downed_deadline_ms`). Leave `properties/0`, `/2`, `/3` at `1`. Edit only those three lines.
5. `tests/features/player/test_items.gd`, in `test_remove_item_lowers_victim_notoriety`: replace the last two assertions after `victim.remove_item_by_uid(int(gear["uid"]))` with one:
   `assert_eq(victim.notoriety, 400.0, "removing gear leaves notoriety unchanged")`. Keep `victim.free()`.
6. Create `tests/features/party/test_party_roles.gd` in the style of `tests/features/party/test_party.gd` (same `extends`, same assert helpers). Use `const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")` and the `Role` enum values:
   - `test_cop_and_criminal_conflict`: `PlayerService.parties_role_conflict([COP], [CRIMINAL])` is true.
   - `test_criminal_and_cop_conflict`: `parties_role_conflict([CITIZEN, CRIMINAL], [COP])` is true.
   - `test_citizens_join_either_side`: `parties_role_conflict([CITIZEN, COP], [CITIZEN])` is false.
   - `test_same_side_no_conflict`: `parties_role_conflict([CRIMINAL], [CRIMINAL, CITIZEN])` is false.
   - `test_empty_roles_no_conflict`: `parties_role_conflict([], [COP])` is false.

## Do not
- Do not touch `PartyService.gd`, `DownedService.gd`, `LootDrop.gd`, or `party_role_conflict`. Do not change any other replication property. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
