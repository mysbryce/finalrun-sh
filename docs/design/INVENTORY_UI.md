# Inventory screen (TAB)

Owner request 2026-11-27: the TAB inventory as close as possible to ROB RUN's. The owner exported ROB RUN's UI layout data (Unity RectTransforms) to `E:/ROBRUN/rrui-export/out`; the in-raid inventory is the tree `KeyboardMouseInventoryDialog` in `space-battle_assets_all/ui.json` (body/loot search: `KeyboardMouseExternalInventoryDialog`). We copy its **geometry** (panel placement, sizes, grid, slot layout). We do **not** copy its look or assets: no sprites, icons, fonts, condensed italic text, lime accent or art from the export or the game. Our style is the one in `docs/design/HUD_LAYOUT.md` ("Visual style"). Once the owner approves the result, this screen becomes the template for a UI skill.

(First version followed the Black Market screenshot, a full-screen shop; the export shows the in-raid inventory is a compact panel on the right with the game visible.)

## Reference layout (from the export, 1920x1080 canvas)
- `ContentPanel` 784 x 804, anchored right-middle, 38 px from the right edge; blurred dark background inside the panel only; the rest of the screen shows the game.
- Header bar 54 high across the panel: over the bag column the title (`BAG`) with the bag's total value right-aligned; over the equipment column a second title (`EQUIPMENT`).
- Bag column: 18 px from the left, 456 wide, starts under the header; grid 6 columns x 9 rows, cells 74 px with a 2 px gap (76 px pitch), 682 high.
- Equipment column: 18 px from the right, 274 wide, starts under the header, 606 high: `weapon_0` 274 x 132 at top; `weapon_1` 274 x 132 at y 142; `vest` 132 x 132 at (0, 284); `backpack` 132 x 132 at (142, 284); bottom row (150 high, at the bottom of the column): `belt` 108 x 150 on the left, four `pocket` cells 74 x 74 (76 pitch, 2x2) on the right.
- Footer bar 54 high across the panel: key hints right-aligned 20 px from the right; an owner label on the left (off in the own inventory).
- Search dialog (`External...`): a second panel 491 x 804 to the left of the inventory panel (right edge 836 px from the screen's right edge, so a 14 px gap), same header/footer, its own 454-wide grid.

## Ours (1280x720 base: reference x 2/3, rounded to our 50 px cell / 1 px gap grid)
| Part | Content |
|---|---|
| Panel | 524 x 536, right 25, top 92; `bg-black/60 backdrop-blur-md`; no full-screen backdrop, no big title, no tabs |
| Header (36) | left: `BAG` + `formatMoney(bagValue)` right-aligned over the bag column; right: `EQUIPMENT` over the equipment column |
| Bag column | left 12, under the header: 6 x 9 grid (54 slots, 50 px cells, 1 px gap, 305 x 458); items take `w x h` cells (see "Item sizes") |
| Equipment column | right 12, width 183, under the header: `PRIMARY` 183 x 88; `SECONDARY` 183 x 88 at y 95; `ARMOR` 88 x 88 at (0, 190) and `BAG` 88 x 88 at (95, 190); `POUCH` label; bottom row at y 304: `POUCH` 72 x 100 on the left, 2x2 `Pocket` cells (50 px, 1 px gap) right-aligned; gear fills these 9 slots in that order |
| Footer (36) | left: the selected item (`label · $value · RARITY`) or `Select an item`; right-aligned hints `[ESC] BACK` (clickable, closes), `[TAB] CLOSE`, `[LMB] SELECT` |

Rarity (display only, by value): `value <= 0` issued (zinc), `< 250` common (emerald), `< 600` rare (violet), else epic (amber).

## Data (Godot → page)
`{"type": "inventory", "data": InventoryView}`, sent when the screen opens and whenever the owner's HUD state changes while it is open:
```json
{"cash": 50, "bagValue": 500, "bagSlots": 36,
 "bag": [{"uid": 3, "id": "jewelry", "label": "Jewelry", "value": 300, "source": "bag"}],
 "gear": [{"uid": 1, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear"}]}
```
Source: `PlayerService.hud_state_of` adds `bag_items` (`loot_bag`) and `gear` (`equipped_gear`) to the owner-only `client_hud_state`.

## Open / close
- `TAB` toggles the screen (only from the plain HUD, not over the body search). `ESC` closes it.
- Page request `inventory.close` (footer `BACK`) closes it; reply `{}`.
- While open: route `/inventory`, browser `MOUSE_FILTER_STOP`, mouse visible; on close route `/`, `IGNORE`, captured.
- Drag and drop (owner request): drag a bag item onto another bag slot to move it there; dropping on an occupied slot swaps the two. Only inside the bag: moving between bag and equipment would let a criminal hide loot from seizure (bag items are seized, gear is not), so it waits for a real equip rule. No drop/use yet.

## Bag slots (server-authoritative)
- Each bag item carries `"slot": int` (0-based grid index). A new or received item gets the first free slot; a received item never keeps the slot it had in another inventory.
- Page request `inventory.move {uid, slot}` -> `Hud` validates shape (`uid > 0`, `0 <= slot < INVENTORY_BAG_SLOTS`, else `bad_params`) and emits `inventory_move_requested(uid, slot)` -> `Main` -> `ServerManager.request_move_bag_item(uid, slot)` -> RPC `server_request_move_bag_item` (alive-gated) -> `PlayerRoleController.move_bag_item(uid, slot)` (swap if occupied) -> `inventory_changed` -> new `client_hud_state` -> new `inventory` message.
- The page moves the tile at once (optimistic) and the next `inventory` message from Godot is the truth.
- Drag uses pointer events (`@dnd-kit/core`), not native HTML5 drag and drop: CEF off-screen rendering does not run native drag sessions.
- Move rule (same on server and page): `slot` is the item's top-left cell. The move succeeds when the item's footprint at `slot` stays inside the grid and covers no other item. Otherwise it is a swap when the footprint covers exactly one other item B, and after the swap (B at the moving item's old slot) both footprints are inside the grid, do not overlap each other and cover nothing else. Anything else is rejected (the tile snaps back).

## Item sizes
- Every item id has a grid size `w x h` (columns x rows); unknown ids are 1x1. The table lives in `lib/utils/ItemUtils.gd` (`ITEM_SIZES`, `size_of(id)`) until item Resources replace it. No rotation yet.
- `item_view` sends `"w"` and `"h"` with every item.
- A new or received bag item takes the first slot (row by row) where its footprint fits.
- Bag full: picking up a lootable, taking a bag item from a body or a loot drop is refused with the notification `Bag full` when no slot fits. Gear never needs bag space.
- Grid: `INVENTORY_BAG_COLUMNS = 6`, `INVENTORY_BAG_SLOTS = 54` (6 x 9, as in the reference).
