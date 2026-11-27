# inventory_ui 10: in-raid inventory panel layout (web)

Design: `docs/design/INVENTORY_UI.md` ("Reference layout", "Ours"). The owner exported ROB RUN's real UI layout: the in-raid TAB inventory is a compact panel on the right with the game visible, not a full-screen page. This card moves our screen to that layout. Behaviour (select, drag, close) stays exactly as it is. Only touch `ui/web/` and `ui/dist/`.

## Rules
- Geometry only. No sprites, icons, fonts or art from the export or the game; no italic, no condensed font, no lime. Accent `amber-400`. System font.
- CSS px on the 1280x720 base (`app/uiScale.ts` zooms the page). Every position/size lives in `layout.ts`.
- `ui/web/src/`: same-folder `./`, cross-folder `@/`; `import type` for types. No new packages.
- Host notes: npm `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'`. Leave the Vite dev server on 5173 running.

## Context (read first)
`src/features/inventory/`: `layout.ts`, `InventoryScreen.tsx` (+ test), `components/{BagGrid, EquipmentPanel, DetailsPanel, PanelHeader, ItemTile, KeyHint}.tsx`, `rarity.ts`, `dragZoom.ts`. `BagGrid` and the DnD code in `InventoryScreen` must keep working unchanged.

## Files
- modify: `src/features/inventory/layout.ts`, `InventoryScreen.tsx`, `InventoryScreen.test.tsx`, `components/EquipmentPanel.tsx`
- delete: `components/DetailsPanel.tsx`, `components/PanelHeader.tsx` (nothing uses them after this card; check with a search first)
- rebuild: `ui/dist/**`

## Steps
1. `layout.ts`: keep `TILE`, `GAP`, `BAG_COLUMNS`, `PITCH`, `BAG_ROWS`, `BAG_GRID`, `cellBox`. Remove `TITLE`, `TABS`, `CASH`, `PANEL_TOP`, `HEADER_HEIGHT`, `HEADER_GAP`, `DETAILS`, `BAG`, `EQUIPMENT`, `FOOTER_HEIGHT`. Add:
   ```ts
   // In-raid panel (ROB RUN export: 784 x 804, right 38, header/footer 54, x 2/3).
   export const PANEL = { right: 25, top: 92, width: 524, height: 536, header: 36, footer: 36, inset: 12 }
   export const BAG_COL = { left: PANEL.inset, top: PANEL.header } // grid BAG_GRID (305 x 458)
   export const EQUIP_COL = { width: 183, left: PANEL.width - PANEL.inset - 183, top: PANEL.header }
   // Equipment slot boxes inside EQUIP_COL (reference: weapons 274x132, vest/backpack 132x132,
   // belt 108x150, pockets 74 px with 76 pitch, bottom row 150 high at the column bottom).
   export const EQUIP_SLOTS = {
     primary: { left: 0, top: 0, w: 183, h: 88 },
     secondary: { left: 0, top: 95, w: 183, h: 88 },
     armor: { left: 0, top: 190, w: 88, h: 88 },
     bag: { left: 95, top: 190, w: 88, h: 88 },
     pouchLabel: { left: 0, top: 284 },
     pouch: { left: 0, top: 304, w: 72, h: 100 },
     pockets: { left: 183 - (2 * TILE + GAP), top: 304 }, // 2x2 grid of TILE cells, GAP apart
   }
   ```
2. `EquipmentPanel.tsx`: same props and `SLOTS` order (`PRIMARY, SECONDARY, ARMOR, BAG, POUCH, POCKET x4`; `gear[i]` fills slot `i`; big slots use `emptyLabel`, pockets `emptyName="Pocket"`). No header inside. Root: `relative`, width `EQUIP_COL.width`, height `EQUIP_SLOTS.pouch.top + EQUIP_SLOTS.pouch.h`. Each slot is a wrapper `<div className="absolute" style={{ left, top }}>` with the `ItemTile` inside at `{ w, h }` from `EQUIP_SLOTS`. The `POUCH` label (`text-xs font-bold uppercase text-white/70`) is absolutely positioned at `pouchLabel`. Pockets: one absolute wrapper at `pockets` holding a `grid grid-cols-2` (`gap: GAP`) of four `TILE x TILE` tiles.
3. `InventoryScreen.tsx` render (all hooks and DnD handlers unchanged; remove the `DetailsPanel`, `PanelHeader`, `TITLE/TABS/CASH/...` imports):
   - Root: `pointer-events-none fixed inset-0 text-white` (no backdrop: the game stays visible).
   - Panel: `pointer-events-auto absolute overflow-hidden bg-black/60 backdrop-blur-md`, style `right: PANEL.right, top: PANEL.top, width: PANEL.width, height: PANEL.height`.
   - Header bar: `absolute inset-x-0 top-0 bg-black/40`, height `PANEL.header`. Inside it, two absolute groups, vertically centred (`flex items-center`, full header height):
     - at `left: BAG_COL.left`, width `BAG_GRID.width`, `justify-between`: `BAG` (`text-lg font-bold uppercase tracking-wide`) and `formatMoney(inventory.bagValue)` (`text-sm font-semibold text-white/80`).
     - at `left: EQUIP_COL.left`, width `EQUIP_COL.width`: `EQUIPMENT` (same title classes).
   - Bag: the existing `DndContext` wraps an absolute `div` at `BAG_COL` containing `BagGrid` (same props as today, including `preview`), plus the existing `DragOverlay`.
   - Equipment: absolute `div` at `EQUIP_COL` (`left`, `top`) containing `EquipmentPanel`.
   - Footer bar: `absolute inset-x-0 bottom-0 flex items-center justify-between bg-black/40`, height `PANEL.footer`, padding-x `PANEL.inset`:
     - left: the selected item (find `selectedUid` in `bag` then `gear`) as three spans in a `flex items-baseline gap-2`: label (`text-sm font-bold`), `formatMoney(value)` (`text-xs font-semibold`), rarity name (`text-[10px] uppercase text-white/60`, from `rarityOf`); with no selection one span `Select an item` (`text-xs text-white/50`).
     - right: `flex items-center gap-4`: the existing `Back` button (`KeyHint k="ESC" label="Back"`, calls `request('inventory.close', {})`), `KeyHint k="TAB" label="Close"`, `KeyHint k="LMB" label="Select"`.
   - `inventory.cash` is no longer shown on this screen (the HUD shows cash; the field stays in the protocol).
4. `InventoryScreen.test.tsx`: in `shows the demo inventory` remove the `INVENTORY` and `$79,900` assertions; keep every other assertion (`$3,530`, 33 `Empty slot`, SECONDARY null, `BAG` button, 1 `POUCH`, 4 `Pocket`, `Select an item`). Add: `getByText('EQUIPMENT')` exists. `bag items render at their slots`, `selecting an item shows details` (the footer label makes the second `Jewelry`), `Back requests close`: unchanged and passing.
5. Delete `DetailsPanel.tsx` and `PanelHeader.tsx` after a search shows no imports remain.
6. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No changes to drag logic, `placement.ts`, `BagGrid.tsx`, `ItemTile.tsx`, `rarity.ts`, the store or the protocol. No search screen changes. No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files changed/deleted, test summary lines, build output list, any step you could not do and why.
