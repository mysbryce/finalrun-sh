# inventory_ui 01: Godot side of the inventory screen (data, TAB/ESC, route, mouse)

Design: `docs/design/INVENTORY_UI.md`. Cards 02/03 build the page; do not touch `ui/web/` or `ui/dist/`.

## Context (already true)
- `features/player/PlayerService.gd` line ~373: `static func hud_state_of(controller) -> Dictionary` returns `{"cash", "bag_value", "notoriety"}`; sent to the owner as `client_hud_state` on spawn and on `inventory_changed` / `role_changed`. `PlayerRoleController` has `loot_bag: Array[Dictionary]` and `equipped_gear: Array[Dictionary]` (items `{"uid", "id", "value", ...}`).
- `tests/features/player/test_hud_state.gd::test_hud_state_has_only_owner_fields` asserts the exact key list.
- `ui/hud/Hud.gd`: `set_money(state)` stores `_money = state.duplicate()`. Panel helpers exist: `_route`, `_navigate(to)`, `_set_panel_input(open)`, `_send_json(json)`, `open_search` / `close_search` / `is_search_open`, `static func search_view(target, items)` (maps each item to `{"uid","id","label","value","source"}` with default source `"bag"`), `static func item_label(id)`, `static func route_request(request, open_target) -> {"reply", "action"}` (methods `ping`, `search.take`, `search.close`; private `_ok_reply(id, data, action)` / `_error_reply(id, text)`). `_on_ipc_message`: on `ready` resends the route (and search); on `request` emits signals from the action.
- `main/Main.gd` `_unhandled_input` matches `key_event.physical_keycode` (keys 1-5, F, G, H, P, R, X, C, E, V, T, Q).
- Rule: `ui/` never calls `ServerManager`. Tests extend `TestCase`; free nodes before asserting.

## Files
- modify: `features/player/PlayerService.gd`, `tests/features/player/test_hud_state.gd`
- modify: `lib/constants/GameConst.gd`
- modify: `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`
- modify: `main/Main.gd`

## Steps
1. `PlayerService.hud_state_of`: add `"bag_items": controller.loot_bag.duplicate(true)` and `"gear": controller.equipped_gear.duplicate(true)`. Update `test_hud_state_has_only_owner_fields` to the sorted keys `["bag_items", "bag_value", "cash", "gear", "notoriety"]`; add to `test_hud_state_counts_bag_and_cash`: `state["bag_items"].size() == 2`.
2. `GameConst.gd` `# HUD` block: `const INVENTORY_BAG_SLOTS: int = 36  # bag grid slots shown (6 x 6) until bag tiers exist`.
3. `Hud.gd` helpers:
   - `static func item_view(item: Dictionary, default_source: String) -> Dictionary`: the per-item mapping `search_view` uses today, with `"source": String(item.get("source", default_source))`. Make `search_view` call `item_view(item, "bag")` (same output as today).
   - `static func inventory_view(money: Dictionary) -> Dictionary`: `{"cash": int(money.get("cash", 0)), "bagValue": int(money.get("bag_value", 0)), "bagSlots": GameConst.INVENTORY_BAG_SLOTS, "bag": [item_view(i, "bag") for each in money.get("bag_items", [])], "gear": [item_view(i, "gear") for each in money.get("gear", [])]}`.
   - `route_request`: add method `inventory.close` -> `_ok_reply(id, {}, ["inventory_close"])` (always ok).
4. `Hud.gd` methods:
   ```gdscript
   func is_inventory_open() -> bool:
       return _route == "/inventory"

   ## TAB: open from the plain HUD, close when open. Ignored over other panels.
   func toggle_inventory() -> void:
       if is_inventory_open():
           close_inventory()
       elif _route == "/":
           _send_inventory()
           _navigate("/inventory")
           _set_panel_input(true)

   func close_inventory() -> void:
       if not is_inventory_open():
           return
       _navigate("/")
       _set_panel_input(false)

   func _send_inventory() -> void:
       _send_json(JSON.stringify({"type": "inventory", "data": inventory_view(_money)}))
   ```
   - `set_money(state)`: after storing, `if is_inventory_open(): _send_inventory()`.
   - `open_search(...)`: before navigating to `/search`, if `is_inventory_open()` call `close_inventory()` (search wins).
   - `_on_ipc_message`: on `ready`, after resending the route, `if is_inventory_open(): _send_inventory()`; on `request`, handle action `["inventory_close"]` (size 1) by calling `close_inventory()`.
5. `main/Main.gd` `_unhandled_input` match: add
   ```gdscript
   KEY_TAB:
       if _hud != null:
           _hud.toggle_inventory()
   KEY_ESCAPE:
       if _hud != null:
           _hud.close_inventory()
   ```
6. `tests/ui/hud/test_hud.gd` add:
   - `test_item_view_default_source`: `Hud.item_view({"uid": 1, "id": "cop_pistol", "value": 0}, "gear")` -> `{"uid": 1, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear"}`.
   - `test_inventory_view`: `Hud.inventory_view({"cash": 50, "bag_value": 300, "bag_items": [{"uid": 3, "id": "jewelry", "value": 300}], "gear": [{"uid": 1, "id": "cop_pistol", "value": 0}]})` -> cash 50, bagValue 300, bagSlots `GameConst.INVENTORY_BAG_SLOTS`, bag[0].label `"Jewelry"` source `"bag"`, gear[0].source `"gear"`; `Hud.inventory_view({})` -> empty `bag` and `gear`.
   - `test_route_inventory_close`: `Hud.route_request({"id": 4, "method": "inventory.close", "params": {}}, 0)` -> reply ok true, action `["inventory_close"]`.
   - `test_toggle_inventory_headless`: `var hud := Hud.new()`, add to root; `hud.toggle_inventory()`; `var opened := hud.is_inventory_open()`; `hud.toggle_inventory()`; `var closed := not hud.is_inventory_open()`; `hud.toggle_inventory()`; `hud.open_search(7, [])`; `var search_won := hud.is_search_open() and not hud.is_inventory_open()`; `hud.toggle_inventory()`; `var ignored := not hud.is_inventory_open()`; `hud.free()`; assert all four.

## Do not
- No new RPCs (reuse `client_hud_state`). No item actions. Do not touch `ui/web/`, `ui/dist/`. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
