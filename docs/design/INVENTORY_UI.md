# Inventory screen (TAB)

Owner request 2026-11-27: an inventory screen as close as possible to the ROB RUN bag/equipment screen (studied from its Steam screenshot of the Black Market, which shows the same BAG and EQUIPMENT panels). We match the **structure**: where panels sit, the slot grid, tile sizes, rarity-tinted tiles, header bars, footer key hints. We do **not** copy its look: no condensed italic display font, no lime accent, no giant watermark title, no icons or art. Our style is the one in `docs/design/HUD_LAYOUT.md` ("Visual style"). Once the owner approves the result, this screen becomes the template for a UI skill.

## Reference structure (observed)
- Full-screen dark backdrop over the game.
- Top-left: big screen title; under it a row of tabs, the active one filled with the accent color.
- Top-right: cash chip.
- Left: a wide panel with a header bar (list of things to pick from).
- Right: `BAG` panel: header bar, then a grid of square slots (6 columns); items fill from the top-left; empty slots show a faint `×`; some items are bigger than one slot.
- Far right: `EQUIPMENT` panel: header bar, two wide weapon slots stacked, then two square slots (armor, bag) side by side, then a `POUCH` label with a 2x2 block of small slots.
- Tiles: background tinted by rarity (green, purple, gold) with a darker gradient; a count or value in the bottom-right corner.
- Bottom: full-width footer bar with key hints (`ESC BACK`, mouse `ACTIONS`).

## Ours
| Part | Content |
|---|---|
| Title | `INVENTORY`, tab row with one active tab `BAG` |
| Top-right | cash chip `formatMoney(cash)` |
| Left panel `DETAILS` | the selected tile: big tile, label, value, source (`BAG` / `GEAR`); "Select an item" when none |
| `BAG` panel | header shows bag value; 6-column grid of 64 px slots, `bagSlots` slots (36); items fill in order, all 1x1 for now (sizes come with item Resources in Phase 3) |
| `EQUIPMENT` panel | slots in order: `PRIMARY` (wide), `SECONDARY` (wide), `ARMOR`, `BAG`, then `POUCH` 2x2; gear items fill these slots in order; empty slots show the slot name faintly |
| Footer | `[ESC] BACK` (clickable, closes), `[TAB] CLOSE`, `[LMB] SELECT` |

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
