# inventory_ui 05: drag and drop inside the bag grid (web)

Design: `docs/design/INVENTORY_UI.md` ("Open / close" DnD bullet, "Bag slots"). Card 04 does the server side in parallel; only touch `ui/web/` and `ui/dist/`.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; same-folder `./`, cross-folder `@/`; `import type` for types.
- Use `@dnd-kit/core` (pointer events). Never native HTML5 `draggable` / `onDragStart`: CEF off-screen rendering does not run native drag sessions.
- The page moves the tile at once (optimistic); the next `inventory` message from Godot replaces the state (it is the truth).
- Host notes: npm `--cache <session temp dir>\npm-cache`; vitest `pool: 'threads'`, Testing Library set up in `src/test/setup.ts`.

## Protocol (copy)
- `InventoryItem` gains `slot: number` (0-based bag grid index; `-1` for gear or unknown).
- Page -> Godot: `request('inventory.move', { uid, slot })`; reply `{}`; error `bad_params`.

## Context (current files, read them first)
- `src/features/inventory/components/BagGrid.tsx`: renders `slots` cells; today item `i` goes in cell `i`.
- `src/features/inventory/components/ItemTile.tsx`: `<button>` tile with `aria-label`, `onSelect(uid)` on click, empty tiles disabled.
- `src/features/inventory/inventoryStore.ts`: `inventory`, `selectedUid`, `setInventory(view)`, `select(uid)`.
- `src/features/inventory/InventoryScreen.tsx`, `InventoryScreen.test.tsx`, `demoInventory.ts`, `layout.ts` (`TILE`, `GAP`).

## Files
- modify: `ui/web/package.json`, `ui/web/package-lock.json`
- modify: `src/lib/ipc/protocol.ts`, `src/features/inventory/inventoryStore.ts`, `components/BagGrid.tsx`, `components/ItemTile.tsx`, `InventoryScreen.tsx`, `demoInventory.ts`, `InventoryScreen.test.tsx`
- create: `src/features/inventory/placement.ts`, `src/features/inventory/placement.test.ts`, `src/features/inventory/inventoryStore.test.ts`
- rebuild: `ui/dist/**`

## Steps
1. In `ui/web/`: `npm install @dnd-kit/core` (with the cache flag).
2. `protocol.ts`: `InventoryItem` adds `slot: number`. `demoInventory.ts`: give the 8 bag items slots `0, 1, 2, 3, 4, 5, 8, 13` (gaps on purpose) and gear `slot: -1`.
3. `placement.ts` (pure):
   ```ts
   // Grid cells for the bag: an item sits at its slot when the slot is valid and
   // free; anything else takes the first free cell (server data is the truth,
   // this only guards against bad or duplicate slots).
   export function placeBagItems(items: InventoryItem[], slots: number): (InventoryItem | null)[]
   // Optimistic move: returns a new bag with `uid` at `slot`, swapping with the
   // item already there. Unknown uid or slot outside 0..slots-1 returns `items` unchanged.
   export function moveBagItem(items: InventoryItem[], uid: number, slot: number, slots: number): InventoryItem[]
   // "slot-7" -> 7, anything else -> null.
   export function slotFromDropId(id: string | number | null | undefined): number | null
   ```
   `placement.test.ts`: placement with valid slots (item at 8 lands in cell 8, cell 6 null); duplicate slot (second item goes to first free cell); slot `-1` and slot `>= slots` go to first free cell; `moveBagItem` to an empty slot; to an occupied slot swaps; unknown uid and slot 36 (with 36 slots) return the same array; `slotFromDropId('slot-7') === 7`, `slotFromDropId('7') === null`, `slotFromDropId(undefined) === null`.
4. `inventoryStore.ts`: add `moveLocal(uid: number, slot: number)`: when `inventory` is set, replace `inventory.bag` with `moveBagItem(bag, uid, slot, inventory.bagSlots)`. `inventoryStore.test.ts`: after `setInventory(DEMO_INVENTORY)`, `moveLocal(<uid of the slot-0 item>, 1)` swaps the slots of the first two items; `setInventory` afterwards replaces the optimistic state.
5. `ItemTile.tsx`: add optional props `dragRef?: (el: HTMLElement | null) => void`, `dragProps?: Record<string, unknown>` (spread on the button: dnd-kit `attributes` + `listeners`), `dragging?: boolean` (adds `opacity-40`), `dropOver?: boolean` (adds `ring-2 ring-white/60` when not selected). Keep click-to-select working.
6. `BagGrid.tsx`:
   - Cells from `placeBagItems(items, slots)`. Each cell is a droppable (`useDroppable({ id: \`slot-${i}\` })`) wrapper `div` sized `TILE x TILE`; an item cell renders a draggable tile (`useDraggable({ id: item.uid })`, pass `setNodeRef` as `dragRef`, `{...attributes, ...listeners}` as `dragProps`, `isDragging` as `dragging`); `dropOver` from the droppable `isOver`.
   - Put the draggable/droppable hooks in small components inside the file (`BagCell`, `DraggableTile`) so hooks are not called in a loop.
7. `InventoryScreen.tsx`:
   - Wrap the bag panel in `<DndContext sensors={sensors} onDragStart onDragEnd onDragCancel>`; `sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 4 } }))` so a plain click still selects.
   - Track `activeUid` in local state for the overlay; `<DragOverlay>` renders an `ItemTile` of that item (size `TILE x TILE`, no handlers) while dragging.
   - `onDragEnd`: `const slot = slotFromDropId(event.over?.id)`; if `slot !== null` and the item's current cell is not `slot`: `moveLocal(uid, slot)` and `move.mutate({ uid, slot })` where `move = useMutation({ mutationFn: (v: { uid: number; slot: number }) => request('inventory.move', v) })`. Clear `activeUid` on end and cancel.
   - Call every hook before the `if (!inventory) return null` line.
8. `InventoryScreen.test.tsx`: keep the existing tests passing (the demo now has gaps: with 8 items in 36 slots there are still 28 `Empty slot` buttons); add `bag items render at their slots`: the 7th rendered bag cell (index 6) is an `Empty slot` and the `Drill` tile (slot 8) is the 9th cell (query the bag grid's direct children in order). Drag gestures are not simulated in jsdom (covered by the pure placement/store tests).
9. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No equipment drag, no bag<->equipment moves. No Godot files. No other new packages. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: installed `@dnd-kit/core` version, files changed/created, test summary lines, build output list, any step you could not do and why.
