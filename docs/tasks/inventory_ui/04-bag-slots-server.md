# inventory_ui 04: server-authoritative bag slots and the move request

Design: `docs/design/INVENTORY_UI.md` ("Bag slots"). Card 05 does the web drag and drop in parallel; do not touch `ui/web/` or `ui/dist/`.

## Context (already true)
- `features/player/PlayerRoleController.gd`: `loot_bag: Array[Dictionary]`; bag items are added by `grant_loot(loot_id, value, issued)` (~line 560, uses `ItemUtils.make_item`) and `receive_item(item, source)` (~line 579, duplicates the item, erases `"source"`, appends to `loot_bag` when source is not `"gear"`). Both emit `inventory_changed`. `remove_item_by_uid(uid)` removes from bag or gear.
- `features/player/PlayerService.gd`: service methods look up `var player := _get_player(peer_id)`, then `player.get_role_controller()` (see `sell_loot`, ~line 221). `_notify(peer_id, text)`.
- `autoload/ServerManager.gd`: alive-gated RPC pattern (e.g. `server_request_sell_loot`, ~line 183):
  ```gdscript
  @rpc("any_peer", "call_remote", "reliable")
  func server_request_sell_loot() -> void:
      var sender: int = multiplayer.get_remote_sender_id()
      if _can_accept_alive_request(sender):
          _players.sell_loot(sender)
  ```
  Client facades are one-liners near line 346: `func request_loot(...) -> void: _send_client_request("server_request_loot", [...])`.
- `ui/hud/Hud.gd`: signals `search_take_requested`, `search_close_requested`; `static func item_view(item, default_source)` maps `{"uid","id","label","value","source"}`; `static func route_request(request, open_target) -> {"reply","action"}` with `_ok_reply(id, data, action)` / `_error_reply(id, text)`; `_on_ipc_message` dispatches actions (`take`, `close`, `inventory_close`).
- `main/Main.gd` `_start_client()` connects `_hud.search_take_requested` / `search_close_requested` to ServerManager right after `add_child(_hud)`.
- `GameConst.INVENTORY_BAG_SLOTS = 36`.
- Tests extend `TestCase`; pure rules are tested on a standalone `PlayerRoleController` (see `tests/features/player/test_items.gd`, which uses `RoleControllerScript.new()` and frees it before asserting).

## Files
- modify: `features/player/PlayerRoleController.gd`, `features/player/PlayerService.gd`, `autoload/ServerManager.gd`
- modify: `ui/hud/Hud.gd`, `main/Main.gd`
- create: `tests/features/player/test_bag_slots.gd`; modify: `tests/ui/hud/test_hud.gd`

## Steps
1. `PlayerRoleController.gd`:
   - `static func first_free_slot(bag: Array) -> int`: smallest `n >= 0` not used by any item's `int(item.get("slot", -1))`.
   - `grant_loot`: before `loot_bag.append(item)`, `item["slot"] = first_free_slot(loot_bag)`.
   - `receive_item`: in the bag branch, before appending: `received["slot"] = first_free_slot(loot_bag)` (always overwrite: a slot from another inventory is meaningless). In the gear branch: `received.erase("slot")`.
   - New:
     ```gdscript
     ## Moves a bag item to a grid slot; swaps with the item already there.
     ## Returns false (no change) for an unknown uid or a slot outside the grid.
     func move_bag_item(uid: int, slot: int) -> bool:
     ```
     Rules: `slot < 0 or slot >= GameConst.INVENTORY_BAG_SLOTS` -> false; find the item with `int(item.get("uid", 0)) == uid` in `loot_bag`, none -> false; if its slot already equals `slot` -> return true without emitting; if another item has that slot, give it the moving item's old slot; set the moving item's slot; `inventory_changed.emit()`; true.
2. `PlayerService.gd`: `func move_bag_item(peer_id: int, item_uid: int, slot: int) -> void`: get player and controller like `sell_loot` (return when null); `if not controller.move_bag_item(item_uid, slot): _notify(peer_id, "Cannot move that item")`.
3. `ServerManager.gd`: RPC `server_request_move_bag_item(item_uid: int, slot: int)` following the alive-gated pattern, calling `_players.move_bag_item(sender, item_uid, slot)`; facade `func request_move_bag_item(item_uid: int, slot: int) -> void: _send_client_request("server_request_move_bag_item", [item_uid, slot])` next to the others.
4. `Hud.gd`:
   - signal `## The page dragged a bag item to a slot. Main forwards it to the server.` `signal inventory_move_requested(item_uid: int, slot: int)`.
   - `item_view`: add `"slot": int(item.get("slot", -1))`.
   - `route_request`: method `inventory.move`: `uid := int(params.get("uid", 0))`, `slot := int(params.get("slot", -1))`; `uid <= 0 or slot < 0 or slot >= GameConst.INVENTORY_BAG_SLOTS` -> `_error_reply(id, "bad_params")`; else `_ok_reply(id, {}, ["move", uid, slot])`.
   - `_on_ipc_message`: action `["move", uid, slot]` (size 3, first `"move"`) -> `inventory_move_requested.emit(int(action[1]), int(action[2]))`.
5. `Main.gd` `_start_client()`: next to the search connects: `_hud.inventory_move_requested.connect(ServerManager.request_move_bag_item)`.
6. `tests/features/player/test_bag_slots.gd` (`extends TestCase`, `const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")`; read values into locals, free the controller, then assert):
   - `test_first_free_slot`: `[]` -> 0; `[{"slot": 0}, {"slot": 2}]` -> 1; `[{"slot": 0}, {"slot": 1}]` -> 2.
   - `test_grant_assigns_slots`: three `grant_loot` -> slots `0, 1, 2`.
   - `test_move_to_empty_slot`: two items; move item B (slot 1) to 5 -> true, B slot 5, A slot 0.
   - `test_move_swaps`: items A (0), B (1); move A to 1 -> A slot 1, B slot 0.
   - `test_move_rejects`: unknown uid -> false; slot -1 -> false; slot `GameConst.INVENTORY_BAG_SLOTS` -> false; slots unchanged.
   - `test_receive_reassigns_slot`: controller has one item (slot 0); `receive_item({"uid": 99, "id": "jewelry", "value": 300, "slot": 7}, "bag")` -> received item slot 1. `receive_item({"uid": 98, "id": "cop_radio", "value": 0, "slot": 3}, "gear")` -> the gear item has no `"slot"` key.
7. `tests/ui/hud/test_hud.gd`: update `test_item_view_default_source` and any exact item-view expectations for the new `"slot": -1` key (search/inventory view tests too); add `test_route_inventory_move`: `{"id": 5, "method": "inventory.move", "params": {"uid": 3, "slot": 4}}` -> ok, action `["move", 3, 4]`; `slot 36` -> `bad_params`; `uid 0` -> `bad_params`.

## Do not
- No moves between bag and gear. Do not touch `ui/web/`, `ui/dist/`. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
