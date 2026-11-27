# inventory_ui 07: multi-cell items in the bag grid (web)

Design: `docs/design/INVENTORY_UI.md` ("Bag slots" move rule, "Item sizes"). Card 06 does the server side in parallel; only touch `ui/web/` and `ui/dist/`. Card 08 restyles the screen later: keep today's colours and classes here.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; same-folder `./`, cross-folder `@/`; `import type` for types.
- `@dnd-kit/core` only (already installed). No native HTML5 drag. No new packages.
- Host notes: npm `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'`; Testing Library in `src/test/setup.ts`. The Vite dev server on 5173 is running: leave it.

## Protocol (copy)
- `InventoryItem` gains `w: number; h: number` (grid columns x rows, >= 1). `slot` is the top-left cell. Grid: 6 columns, `bagSlots` = 54 (9 rows).
- Move rule (must match the server): moving item X to `slot` succeeds when X's footprint at `slot` is inside the grid and covers no other item (X's own old cells do not count). Otherwise it is a swap when the footprint covers exactly one other item B and, with B moved to X's old slot, both footprints are inside the grid, share no cell, and cover no third item. Anything else: no change.

## Context (current files, read them first)
- `src/features/inventory/placement.ts` (+ `placement.test.ts`): `placeBagItems(items, slots)` returns one entry per cell (1x1 only), `moveBagItem(items, uid, slot, slots)`, `slotFromDropId(id)`.
- `components/BagGrid.tsx`: CSS grid of `BagCell` (droppable `slot-i`) with `DraggableTile` inside.
- `InventoryScreen.tsx`: `DndContext`, `DragOverlay`, `onDragEnd` (uses `placeBagItems(...).findIndex`), `moveLocal` + `move.mutate`.
- `components/ItemTile.tsx`: props `dragRef`, `dragProps`, `dragging`, `dropOver`.
- `inventoryStore.ts` (`moveLocal`), `inventoryStore.test.ts`, `demoInventory.ts`, `InventoryScreen.test.tsx`, `layout.ts` (`TILE` 50, `GAP` 1).

## Files
- modify: `src/lib/ipc/protocol.ts`, `src/features/inventory/{layout.ts, placement.ts, placement.test.ts, inventoryStore.ts, inventoryStore.test.ts, demoInventory.ts, InventoryScreen.tsx, InventoryScreen.test.tsx}`, `components/{BagGrid.tsx, ItemTile.tsx}`
- modify if their fixtures need `w`/`h` for the type check: `src/lib/ipc/bridge.test.ts`
- rebuild: `ui/dist/**`

## Steps
1. `protocol.ts`: `InventoryItem` adds `w: number; h: number`.
2. `layout.ts`: add `export const BAG_COLUMNS = 6` and `export const PITCH = TILE + GAP` and
   ```ts
   // CSS px box of an item (or cell) whose top-left cell is `slot`.
   export function cellBox(slot: number, w = 1, h = 1) {
     const col = slot % BAG_COLUMNS
     const row = Math.floor(slot / BAG_COLUMNS)
     return { left: col * PITCH, top: row * PITCH, width: w * TILE + (w - 1) * GAP, height: h * TILE + (h - 1) * GAP }
   }
   ```
3. `placement.ts` (pure; rewrite; `cols` is always passed, callers use `BAG_COLUMNS`):
   ```ts
   export type Placed = { item: InventoryItem; slot: number }
   // Cells covered by a w x h item at `slot`; [] when any part is outside the grid.
   export function footprint(slot: number, w: number, h: number, cols: number, slots: number): number[]
   // Items with a valid, non-overlapping slot keep it (first come first served);
   // the others take the first slot where they fit; items that fit nowhere are left out.
   export function placeBagItems(items: InventoryItem[], slots: number, cols: number): Placed[]
   // uid covering each cell, or null.
   export function occupancy(placed: Placed[], slots: number, cols: number): (number | null)[]
   // Optimistic move with the protocol's move rule (works on placeBagItems' result);
   // returns `items` itself (same reference) when nothing changes or the move is rejected.
   export function moveBagItem(items: InventoryItem[], uid: number, slot: number, slots: number, cols: number): InventoryItem[]
   // Top-left slot when the pointer is over `pointerSlot` and the item was grabbed at
   // cell (offCol, offRow) of itself; null when that would start left of column 0 or above row 0.
   export function targetSlot(pointerSlot: number, offCol: number, offRow: number, cols: number): number | null
   // "slot-7" -> 7, anything else -> null.  (unchanged)
   export function slotFromDropId(id: string | number | null | undefined): number | null
   ```
   `footprint` rows = `Math.ceil(slots / cols)`.
4. `placement.test.ts`: replace the old cases (helper `item(uid, slot, w = 1, h = 1)`; 54 slots, 6 cols):
   - `footprint(0, 2, 3, 6, 54)` = `[0, 1, 6, 7, 12, 13]`; `footprint(5, 2, 1, 6, 54)` = `[]`; `footprint(48, 1, 2, 6, 54)` = `[]`.
   - placement: a 2x2 at 0 and a 1x1 at 7 -> the 1x1 overlaps, so it moves to the first fit (slot 2); a slot of -1 takes the first fit; an item that fits nowhere is left out (fill the grid with nine 2x3 items, add one 1x1: 9 placed).
   - `occupancy`: 2x2 at 0 -> cells 0, 1, 6, 7 hold its uid, cell 2 is null.
   - `moveBagItem`: 1x1 to an empty slot; 1x1 onto 1x1 swaps; 2x2 at 0 moved to 7 (overlaps its own old cells) succeeds; 2x2 to 5 (past the edge) returns the same array; 2x1 E (slot 2) onto 2x2 C (slot 0) swaps (E 0, C 2); 2x1 E onto two 1x1 items (slots 0, 1) returns the same array; unknown uid returns the same array.
   - `targetSlot(14, 1, 1, 6)` = 7; `targetSlot(12, 1, 0, 6)` = null (left of column 0); `targetSlot(3, 0, 1, 6)` = null (above row 0).
   - `slotFromDropId` cases stay.
5. `inventoryStore.ts`: `moveLocal` calls `moveBagItem(inv.bag, uid, slot, inv.bagSlots, BAG_COLUMNS)` (import from `./layout`). `inventoryStore.test.ts`: keep the swap test working with the new demo (pick two 1x1 items from the demo by id), keep the `setInventory` replaces-state test.
6. `demoInventory.ts`: `bagSlots: 54`; bag (uid, id, slot, w x h): 1 jewelry 0 1x1; 2 electronics 1 2x1; 3 cash_box 3 2x2; 6 lockpick 5 1x1; 7 drill 11 1x3; 4 gold_bar 12 2x1; 5 painting 14 2x3; 8 phone 18 1x2. Keep labels and values as today. Gear items get `w: 1, h: 1`.
7. `BagGrid.tsx`: props add nothing new except `preview?: { slot: number; w: number; h: number; ok: boolean } | null`. Render a `relative` box of size `cellBox(0, BAG_COLUMNS, rows)` (`rows = Math.ceil(slots / BAG_COLUMNS)`) with, in this order:
   Positioning rule: every cell and every item is a wrapper `<div className="absolute" style={cellBox(...)}>` with the `ItemTile` inside (sized to the box). Never put `absolute` on the `ItemTile` button: it already has `relative`, which would win.
   1. one `BagCell` per slot `i`: the wrapper at `cellBox(i)` is the droppable (`slot-${i}`). A cell not covered by an item (from `occupancy`) renders the empty `ItemTile` (`aria-label` `Empty slot`); a covered cell renders an empty `div` (no button).
   2. one `DraggableTile` per placed item: wrapper at `cellBox(slot, item.w, item.h)`, `ItemTile` inside sized to that box (the button stays the draggable node).
   3. when `preview` is set: one `div` with `pointer-events-none absolute` at `cellBox(preview.slot, preview.w, preview.h)`, classes `ring-2 ring-inset ring-white/70 bg-white/10` when `ok`, else `ring-2 ring-inset ring-red-500/80 bg-red-500/15`.
   Remove `dropOver` from `BagCell`/`DraggableTile` and from `ItemTile` (prop and class) since the preview replaces it.
8. `InventoryScreen.tsx`:
   - `DndContext` gets `collisionDetection={pointerWithin}` (import from `@dnd-kit/core`) so `over` is the cell under the pointer.
   - `onDragStart`: store `activeUid` (state) and the grab offset in a `useRef<{ offCol: number; offRow: number }>`. `event.active.rect.current.initial` is still null inside `onDragStart`, so measure the grabbed tile directly: `const r = (event.activatorEvent?.target as Element | null)?.closest('button')?.getBoundingClientRect()`; with `clientX/clientY` from `event.activatorEvent` (a `PointerEvent`) and `w`, `h` of the dragged item from the store: `offCol = clamp(Math.floor((clientX - r.left) / (r.width / w)), 0, w - 1)`, same for rows with `top/height/h`. When `r` is undefined use `{ offCol: 0, offRow: 0 }`.
   - `onDragMove` (or `onDragOver`): `pointer = slotFromDropId(event.over?.id)`; `target = pointer === null ? null : targetSlot(pointer, offCol, offRow, BAG_COLUMNS)`; set `preview` state to `null` when `target` is null, else `{ slot: target, w, h, ok }` where `ok` = target is the item's current slot or `moveBagItem(bag, uid, target, bagSlots, BAG_COLUMNS) !== bag`. Only call `setPreview` when the value changes (compare slot and ok) to avoid re-render loops.
   - `onDragEnd`: same target; if not null, not the current slot, and `moveBagItem(...) !== bag`: `moveLocal(uid, target)` and `move.mutate({ uid, slot: target })`. Clear `activeUid` and `preview` on end and on cancel.
   - Current slot comes from `placeBagItems(bag, bagSlots, BAG_COLUMNS)`.
   - `DragOverlay` renders the active item's `ItemTile` at its full `cellBox(0, w, h)` width/height.
   - Pass `preview` to `BagGrid`. All hooks stay above `if (!inventory) return null`.
9. `InventoryScreen.test.tsx`: update for the new demo: `Empty slot` buttons = 33 (54 cells - 21 covered); `bag items render at their slots` becomes: `screen.getByRole('button', { name: 'Drill' }).parentElement` has `left: 255px; top: 51px; width: 50px; height: 152px`, and the `Painting` button's `parentElement` has `left: 102px; top: 102px; width: 101px; height: 152px` (`toHaveStyle`). Other tests unchanged.
10. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No rotation, no equipment drag, no bag<->equipment moves. No restyling (card 08). No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files changed, test summary lines, build output list, any step you could not do and why.
