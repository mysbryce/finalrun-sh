# ui_impl 15b: owner inventory states and the body-search grid beside it (web)

Design source: `docs/ui-design/04-hud.md` section 2 drawings "Body search with owner inventory" and "Owner inventory", section 3 layout tables for both (exact x/y/w/h), the layout paragraph under section 3 ("Body-search panel remains right 558 and owner inventory right 25 ..."), section 4 "Inventory and body search" (Owner inventory, Body search, Availability bullets), "Body scrolling geometry", section 5 paragraphs 2-3, section 8. `docs/ui-design/flow.md` `/inventory` and `/search` rows. Read first: `ui/web/src/app/router.tsx`, `ui/web/src/app/showsHud.ts` (+ test), `ui/web/src/main.tsx` (`#search` dev branch), `ui/web/src/features/inventory/` (all, incl. tests), `ui/web/src/features/search/` (all), `ui/web/src/lib/grid/` (all), `ui/web/src/lib/ipc/protocol.ts` (`SearchView`, `SearchItem`, `InventoryView`), `ui/web/src/lib/ipc/bridge.ts` (`request`, its 5 s timeout and error codes), `ui/web/src/lib/ui/Dropdown.tsx` (optional `scrollIntoView?.` call), `ui/web/public/settings-schema.json` (`bind_search_take`, `bind_sell_loot` entries).

## Decisions for this card (supervisor)

### Positioning (same rule as card 14b)
- Each screen root is `fixed inset-0 pointer-events-none`. Panel boxes and rows are absolutely placed siblings in screen px (the page is pinned to 1280 × 720, so `left 395` equals the spec's `right 558`). Every interactive or scrollable element sets `pointer-events-auto`: the search panel box, the body scroll container, the close button, and the inventory panel as today. Tiles inside the scroll container use content-relative `cellBox(slot, w, h)` (not screen px).

### Body search panel (replaces the centred list)
- Geometry in new `features/search/layout.ts`: `SEARCH_PANEL` { left 395, top 92, width 327, height 536 }; header top 92 height 36 with title (left 406, width 226) and item count (left 638, width 73); `BODY_VIEWPORT` { left 406, top 128, width 305, height 458 } (= `BAG_GRID`); `BODY_SCROLLBAR` { left 714, top 128, width 4, height 458 }; footer top 592 height 36 with error (left 406, width 135), close (left 548, width 72) and take hint (left 627, width 84), each 22 high at top 599.
- Packing: new pure helper in `lib/grid/placement.ts`: `packRows<T extends { uid: number; w: number; h: number }>(items: T[], cols: number, minRows: number): { packed: { item: T; slot: number }[]; rows: number }` (do not reuse the name `Placed`). Items go in input order to the first free slot scanning row-first; a row is added whenever an item does not fit; an item wider than `cols` is skipped; `rows = max(minRows, lastOccupiedRow + 1)`. `footprint()` may help with the cell checks. Search uses `packRows(search.items, BAG_COLUMNS, BAG_ROWS)` and ignores `slot` (always -1, layout only).
- `components/BodyGrid.tsx`: scroll container exactly at `BODY_VIEWPORT`, classes `overflow-y-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden pointer-events-auto`; inner content div `data-testid="body-content"` with height `rows * PITCH - GAP`; a neutral empty tile in every cell (like the owner bag) and item tiles (`key={item.uid}`) via the shared `ItemTile` at `cellBox(slot, w, h)`. Keep the scroll container mounted while the panel is open (no changing `key`) so scroll position and tile identity survive item changes. Each item tile sits in a wrapper div with `onFocus={(e) => (e.target as HTMLElement).scrollIntoView?.({ block: 'nearest' })}`.
- Custom thumb inside `BODY_SCROLLBAR`, hidden when `contentHeight <= 458`: `thumbH = max(24, 458 * 458 / contentHeight)`, `top = 128 + scrollTop * (458 - thumbH) / (contentHeight - 458)`, with `scrollTop` kept in state from `onScroll`.
- Take: clicking an item tile sends `request('search.take', { target, uid })`. Per-UID pending `Set<number>` in component state: the uid leaves the set when the request settles (the host acks right away; server refusals such as "Bag full" only arrive as HUD notifications) and when the item is gone from the next `search` snapshot. A pending tile's wrapper gets `opacity-50 cursor-wait` and `aria-busy="true"`, and the click handler ignores it. Error replies show readable text in the footer error slot: `no_search` -> `Search closed.`, `timeout` -> `No answer from the game.`, anything else -> `Could not take the item.`; the error clears on the next take or the next `search` snapshot. `# ponytail:` "Bag full" shows as a HUD notification after the search closes.
- Header: title from `search.title`, count `<n> items`. Empty body: `Nothing left to take` centred in the viewport. Footer: close button `KeyHint` `Q` / `Close` sending `request('search.close', { target })`; take hint `KeyHint` `LMB` / `Take`.
- `search` null while on `/search`: the panel shows with header title `Searching…`, no count, no grid, and the close button disabled.
- Remove the virtualised list (`components/SearchItemRow.tsx` and the `@tanstack/react-virtual` import). Leave the package in `package.json` and report that it is unused.

### Owner inventory
- `InventoryScreen` gets a prop `embedded?: boolean` (default false). Embedded (used on `/search`): no `Back` button and no `TAB Close` hint in the footer. Deliberate deviation from the combined drawing (A30/A31): `inventory.close` does nothing on `/search`, search owns closing.
- Store `inventoryStore.ts`: add `committed: InventoryView | null`, `notice: string | null`, `seq: number`. `setInventory(view)` sets `inventory` and `committed` to `view`, `seq + 1`, `notice = null` (selection rule as today). New `revert(notice: string | null)`: when `committed` is null do nothing; else `inventory = committed`, `notice`. `moveLocal` unchanged.
- New hook `features/inventory/useConfirmedMove.ts`: `useConfirmedMove(): (uid: number, slot: number) => void`. The returned `commitMove` calls `moveLocal(uid, slot)`, sends `request('inventory.move', { uid, slot })` and (re)starts a single `MOVE_CONFIRM_MS` timer (`MOVE_CONFIRM_MS = 5000` in `features/inventory/layout.ts`). When the store's `seq` changes, the timer is cleared. On expiry: `revert('Move could not be confirmed.')`. A rejected request: code `timeout` -> same as expiry; any other code -> `revert(null)` and clear the timer. Clear the timer on unmount. `InventoryScreen.onDragEnd` calls `commitMove` instead of `moveLocal` + mutation (drop the `useMutation` there).
- Footer: `notice` replaces the selected-item text until the next snapshot clears it.
- `inventory` null while the screen is shown: keep the panel, header bag value `—`, `<BagGrid items={[]} slots={BAG_COLUMNS * BAG_ROWS} ... />` with no drag, empty equipment column, footer text `Loading inventory…`; the Back button (when not embedded) stays enabled. (No separate "unavailable" state: Godot never sends a null inventory.)

### Routes, preview, schema, comments
- `router.tsx`: `/search` renders `<SearchScreen />` and `<InventoryScreen embedded />`. `showsHud('/search')` becomes false; move `/search` to the hidden list in `showsHud.test.ts`.
- `main.tsx` `#search` dev branch also calls `useInventoryStore.getState().setInventory(DEMO_INVENTORY)`. `demoSearch.ts` stays as is (it already packs to 15+ rows).
- `ui/web/public/settings-schema.json`: `bind_search_take` gets `"capability": "debug_shortcuts"` and `"unavailable": "hidden"` (the `bind_sell_loot` shape). The docs copy is already updated, so `schema.test.ts` stays green.
- `features/inventory/layout.ts`: replace the comments on lines 3 and 7-8 that cite another game's export with references to the `04-hud.md` "Owner inventory" table.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages. Px geometry from layout constants (pinned under UI scale).
- Tests with fake timers: `vi.useFakeTimers()`, advance with `act(() => vi.advanceTimersByTime(ms))`, flush promises with `await act(async () => {})`; never `findBy*` or `waitFor` under fake timers. Seed stores with `setInventory(structuredClone(DEMO_INVENTORY))` (a new reference each time). Every `beforeEach` store reset includes `committed: null, notice: null, seq: 0`.
- Host notes: run npm from PowerShell in `d:\FinalRun\ui\web` (Git Bash's `D:/` path breaks vitest); npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; do not start a Vite dev server; `ui/dist/assets` is not readable for you. Do not edit Godot files.

## Files
- create: `ui/web/src/features/search/layout.ts`, `ui/web/src/features/search/components/BodyGrid.tsx`, `ui/web/src/features/search/SearchScreen.test.tsx`, `ui/web/src/features/inventory/useConfirmedMove.ts`, `ui/web/src/features/inventory/useConfirmedMove.test.ts`
- modify: `ui/web/src/lib/grid/placement.ts`, `ui/web/src/lib/grid/placement.test.ts`, `ui/web/src/features/search/SearchScreen.tsx`, `ui/web/src/features/inventory/InventoryScreen.tsx`, `ui/web/src/features/inventory/InventoryScreen.test.tsx`, `ui/web/src/features/inventory/inventoryStore.ts`, `ui/web/src/features/inventory/inventoryStore.test.ts`, `ui/web/src/features/inventory/layout.ts`, `ui/web/src/app/router.tsx`, `ui/web/src/app/showsHud.test.ts`, `ui/web/src/main.tsx`, `ui/web/public/settings-schema.json` (one entry)
- delete: `ui/web/src/features/search/components/SearchItemRow.tsx`

## Steps
1. `packRows` + tests: row-first order; a 2×2 after a 6×1 lands at slot 6; 12 items of 6×1 give `rows` 12; empty input gives `minRows`; an item wider than `cols` is skipped.
2. Search layout, `BodyGrid`, `SearchScreen`.
3. Inventory store, `useConfirmedMove`, embedded prop, loading state.
4. Router, `showsHud` test, `main.tsx`, schema entry, layout comments.
5. Tests:
   - `SearchScreen.test.tsx` (mock `request`): tiles are placed at the packed `cellBox` positions; 14 rows of content -> `getByTestId('body-content')` height `14 * 51 - 1` px; clicking a tile sends `search.take` with `{ target, uid }` exactly once and a second click while the request is unsettled sends nothing; a rejection with `no_search` shows `Search closed.` and the tile is clickable again; focusing a tile wrapper calls a stubbed `Element.prototype.scrollIntoView` with `{ block: 'nearest' }`; empty items show `Nothing left to take`; null search shows `Searching…` with Close disabled; the close button sends `search.close`.
   - `inventoryStore.test.ts`: `revert` restores `committed` and sets `notice`; `revert` with null `committed` changes nothing; `setInventory` clears `notice` and bumps `seq`.
   - `useConfirmedMove.test.ts` (`renderHook`, fake timers, mocked `request` that stays pending): after `commitMove`, 5000 ms later the store `notice` is `Move could not be confirmed.` and the item is back at its committed slot; a `setInventory` before 5000 ms cancels it; a rejection with `bad_params` reverts at once with `notice` null; a rejection with `timeout` gives the confirm notice.
   - `InventoryScreen.test.tsx`: replace "renders nothing without data" with: null inventory shows `Loading inventory…` and the Back button; `embedded` hides `Back`; the footer shows `notice` when set.
6. Checks: `npm run test`, `npm run build` (in `ui/web/`, from PowerShell).

## Do not
- No Godot files. Do not edit `docs/`. Do not run git. No owner-bag changes beyond the states above (no rotate, equip, drop, use, cross-panel drag).

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files created/changed/deleted, web test summary line, build output list, whether `@tanstack/react-virtual` is still used anywhere, anything you could not do and why.
