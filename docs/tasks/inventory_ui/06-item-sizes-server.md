# inventory_ui 06: item sizes, grid fit and "Bag full" (server)

Design: `docs/design/INVENTORY_UI.md` ("Bag slots" move rule, "Item sizes"). Card 07 does the web side in parallel; do not touch `ui/web/` or `ui/dist/`.

## Context (already true, read these first)
- `lib/utils/ItemUtils.gd`: stateless item helpers (`make_item`, `find_by_uid`, ...).
- `lib/constants/GameConst.gd` line ~112: `const INVENTORY_BAG_SLOTS: int = 36  # ...`.
- `features/player/PlayerRoleController.gd`: `grant_loot` (~l.560) sets `item["slot"] = first_free_slot(loot_bag)`; `receive_item` (~l.580) bag branch sets `received["slot"] = first_free_slot(loot_bag)`, gear branch erases `"slot"`; `static func first_free_slot(bag)` and `func move_bag_item(uid, slot) -> bool` (~l.598-631).
- `features/player/PlayerService.gd` ~l.340-368: the lootable interaction (`Already looted`, `Too far away`, then `lootable.server_smash(player)` / `server_lockpick(player)`). Controller lookup elsewhere in this file: `player.get_role_controller()`.
- `features/downed/DownedService.gd`: `_body_on_take` (~l.617) removes the item from the victim, then `taker_controller.receive_item(removed, source)` for a CRIMINAL; the search take (~l.170) notifies `"That item is no longer there"` whenever `container.take` fails.
- `features/heist/LootDrop.gd` `_on_take` (~l.76) calls `controller.receive_item(item, String(item.get("source", "bag")))`.
- `ui/hud/Hud.gd` `static func item_view(item, default_source)` returns `uid,id,label,value,source,slot`.
- Tests: `tests/features/player/test_bag_slots.gd`, `tests/ui/hud/test_hud.gd` (`test_route_inventory_move` uses slot 36 as the bad slot; item-view expectations are exact dictionaries).

## Files
- modify: `lib/constants/GameConst.gd`, `lib/utils/ItemUtils.gd`, `features/player/PlayerRoleController.gd`, `features/player/PlayerService.gd`, `features/downed/DownedService.gd`, `features/heist/LootDrop.gd`, `ui/hud/Hud.gd`
- modify: `tests/features/player/test_bag_slots.gd`, `tests/ui/hud/test_hud.gd`, `tests/lib/utils/test_item_utils.gd`

## Steps
1. `GameConst.gd`: `INVENTORY_BAG_SLOTS` becomes `54  # bag grid slots (6 columns x 9 rows)`; add right above it `const INVENTORY_BAG_COLUMNS: int = 6`.
2. `ItemUtils.gd`:
   ```gdscript
   ## Grid size (columns x rows) of each item id in the bag. Unknown ids are 1x1.
   ## ponytail: a table until item Resources carry their own size.
   const ITEM_SIZES: Dictionary = {
       "valuables": Vector2i(1, 2),
       "jewelry": Vector2i(1, 1),
       "electronics": Vector2i(2, 1),
       "cash_box": Vector2i(2, 2),
       "gold_bar": Vector2i(2, 1),
       "painting": Vector2i(2, 3),
   }

   static func size_of(item_id: String) -> Vector2i:
       return ITEM_SIZES.get(item_id, Vector2i(1, 1))
   ```
3. `PlayerRoleController.gd` (replace `first_free_slot`; keep the doc-comment style `##`):
   - `static func footprint(slot: int, size: Vector2i) -> Array[int]`: cells covered by an item whose top-left cell is `slot`; columns `GameConst.INVENTORY_BAG_COLUMNS`, rows `GameConst.INVENTORY_BAG_SLOTS / GameConst.INVENTORY_BAG_COLUMNS`. Returns `[]` when `slot < 0`, or `col + size.x > columns`, or `row + size.y > rows`. Cells are `(row + dy) * columns + (col + dx)`.
   - `static func fits_at(bag: Array, slot: int, size: Vector2i, ignore_uids: Array) -> bool`: `footprint` not empty and none of its cells is covered by an item of `bag` whose uid is not in `ignore_uids` (an item covers `footprint(int(item.get("slot", -1)), ItemUtils.size_of(String(item.get("id", ""))))`).
   - `static func find_fit(bag: Array, size: Vector2i) -> int`: first `slot` in `0..INVENTORY_BAG_SLOTS-1` with `fits_at(bag, slot, size, [])`, else `-1`.
   - `func can_fit_bag(item_id: String) -> bool`: `find_fit(loot_bag, ItemUtils.size_of(item_id)) != -1`.
   - `grant_loot`: `item["slot"] = find_fit(loot_bag, ItemUtils.size_of(loot_id))`. `receive_item` bag branch: `received["slot"] = find_fit(loot_bag, ItemUtils.size_of(String(received.get("id", ""))))`. Add one comment line above each: `# -1 when the bag is full; callers check can_fit_bag() first.`
   - `move_bag_item(uid, slot)` keeps its signature and doc comment; new body:
     1. `slot < 0 or slot >= GameConst.INVENTORY_BAG_SLOTS` -> false.
     2. Find `moving` (uid) in `loot_bag`, none -> false. `old_slot := int(moving.get("slot", -1))`; `old_slot == slot` -> true (no emit). `size := ItemUtils.size_of(String(moving.get("id", "")))`.
     3. If `fits_at(loot_bag, slot, size, [uid])`: `moving["slot"] = slot`, emit `inventory_changed`, true.
     4. Else swap: collect the other items whose footprint shares a cell with `footprint(slot, size)`. Exactly one item `other` is required, else false. Let `other_size`, `a := footprint(slot, size)`, `b := footprint(old_slot, other_size)`. Require `a` and `b` not empty, no shared cell between `a` and `b`, `fits_at(loot_bag, slot, size, [uid, other_uid])` and `fits_at(loot_bag, old_slot, other_size, [uid, other_uid])`. Otherwise false. Then `other["slot"] = old_slot`, `moving["slot"] = slot`, emit, true.
4. `PlayerService.gd` lootable interaction: after the `Too far away` check and before `var value: int = lootable.value`:
   ```gdscript
   var controller := player.get_role_controller()
   if controller != null and not controller.can_fit_bag(lootable.loot_id):
       _notify(peer_id, "Bag full")
       return
   ```
   (If a local named `controller` already exists in that function, reuse it instead of declaring a new one.)
5. `DownedService.gd`:
   - `_body_on_take`: right after the existing line `var source := String(item.get("source", "bag"))` (~l.632) and before `var removed: Dictionary = victim_controller.remove_item_by_uid(...)` (~l.633), insert: if `taker_controller.role == RoleController.Role.CRIMINAL and source != "gear" and not taker_controller.can_fit_bag(String(item.get("id", "")))` -> `return {"ok": false, "reason": "bag_full"}`. Do not change the cop branch.
   - search take (~l.171): when `result` is not ok, notify `"Bag full"` if `String(result.get("reason", "")) == "bag_full"`, else keep `"That item is no longer there"`.
6. `LootDrop.gd` `_on_take`: before `controller.receive_item(...)`: `var source := String(item.get("source", "bag"))`; if `source != "gear" and not controller.can_fit_bag(String(item.get("id", "")))` -> `return {"ok": false, "reason": "bag_full"}`; then `controller.receive_item(item, source)`. No game code calls take on a LootDrop container yet, so `bag_full` here is only a reason code: do not add a notify path for it.
7. `Hud.gd` `item_view`: compute `var size := ItemUtils.size_of(String(item.get("id", "")))` and add `"w": size.x, "h": size.y` to the returned dictionary (after `"slot"`).
8. Tests (`extends TestCase`; read values into locals, free the controller, then assert):
   - `tests/lib/utils/test_item_utils.gd`: add `test_item_sizes`: `ItemUtils.size_of("painting") == Vector2i(2, 3)`, `size_of("unknown_thing") == Vector2i(1, 1)`.
   - `test_bag_slots.gd`: delete `test_first_free_slot`. Existing tests keep passing (jewelry is 1x1). Add:
     - `test_footprint`: `footprint(0, Vector2i(2, 3)) == [0, 1, 6, 7, 12, 13]`; `footprint(5, Vector2i(2, 1)) == []` (past the right edge); `footprint(48, Vector2i(1, 2)) == []` (past the bottom); `footprint(-1, Vector2i(1, 1)) == []`.
     - `test_grant_finds_fit`: `grant_loot("cash_box", 100)` -> slot 0; then `grant_loot("electronics", 100)` -> slot 2; then `grant_loot("jewelry", 100)` -> slot 4.
     - `test_move_multi_cell`: cash_box at 0; move it to 7 -> true, slot 7 (overlapping its own old cells is fine); move to 5 -> false (past the edge), slot stays 7.
     - `test_move_swap_rules` (three fresh controllers):
       1. jewelry A (slot 0), jewelry B (slot 1): move A to 1 -> true, A 1, B 0.
       2. cash_box C (slot 0), electronics E (slot 2): move E to 0 -> true (swap: E at `[0,1]`, C at `footprint(2, 2x2) = [2,3,8,9]`, disjoint), E 0, C 2.
       3. jewelry J1 (0), jewelry J2 (1), electronics E (2): move E to 0 -> false (its footprint covers two items), slots unchanged.
     - `test_bag_full`: grant `painting` 9 times (2x3 each: 3 per band of 3 rows x 3 bands = 9) -> all slots >= 0; `can_fit_bag("jewelry")` is false; `grant_loot("jewelry", 1)` returns an item with slot -1.
   - `test_hud.gd`: exact item-view expectations add `"w": 1, "h": 1` for the ids used there (check each id against `ITEM_SIZES`; e.g. `cash_box` is `"w": 2, "h": 2`); in `test_route_inventory_move` the bad slot becomes `54` (assert message `"slot 54 is bad params"`), and slot `36` is now valid (add one assert that it returns ok).
9. Run Done-when.

## Do not
- No rotation. No moves between bag and gear. No changes to the cop seizure branch. Do not touch `ui/web/`, `ui/dist/`. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found` and its C# stack lines, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
