# inventory_ui 03: inventory screen on the web UI (+ component tests)

Design: `docs/design/INVENTORY_UI.md` (structure, data, open/close). Card 01 did the Godot side; card 02 added Testing Library (`src/test/setup.ts`). Only touch `ui/web/` and `ui/dist/`.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; `lib/` never imports `features/`; a feature never imports another feature's files; cross-folder `@/`, same-folder `./`; `import type` for types. `formatMoney` is in `@/lib/format`.
- Display only plus the close request. The page gets clicks while open (Godot frees the mouse); keys stay with Godot (TAB/ESC close).
- Style: structure as in the design doc; our look: system font, NO italic, NO condensed font, NO lime: accent `amber-400`, panels zinc. Host notes: npm `--cache <session temp dir>\npm-cache`; vitest `pool: 'threads'`. No new packages.
- Pixel numbers are CSS px on the 1280x720 base (the page is zoomed to the window by `app/uiScale.ts`).

## Protocol (copy)
- Godot -> page `{"type":"inventory","data": InventoryView}`; `InventoryView = { cash: number; bagValue: number; bagSlots: number; bag: InventoryItem[]; gear: InventoryItem[] }`; `InventoryItem = { uid: number; id: string; label: string; value: number; source: string }`.
- Godot -> page `{"type":"route","to":"/inventory"}` opens, `"/"` closes.
- Page -> Godot: `request('inventory.close', {})` (footer BACK button).

## Files
- modify: `src/lib/ipc/protocol.ts`, `src/lib/ipc/bridge.ts`, `src/lib/ipc/bridge.test.ts`, `src/app/router.tsx`, `src/main.tsx`
- create in `src/features/inventory/`: `inventoryStore.ts`, `rarity.ts`, `rarity.test.ts`, `layout.ts`, `demoInventory.ts`, `InventoryScreen.tsx`, `InventoryScreen.test.tsx`, `components/ItemTile.tsx`, `components/PanelHeader.tsx`, `components/BagGrid.tsx`, `components/EquipmentPanel.tsx`, `components/DetailsPanel.tsx`, `components/KeyHint.tsx`
- rebuild: `ui/dist/**`

## Steps
1. `protocol.ts`: add `InventoryItem`, `InventoryView`; add `| { type: 'inventory'; data: InventoryView }` to `GodotToPage`. `bridge.ts`: `BridgeDeps.setInventory: (view: InventoryView) => void`; case `'inventory'` -> `deps.setInventory(message.data as InventoryView)`. `bridge.test.ts`: `makeDeps()` gets `setInventory: vi.fn()`; add `inventory message calls setInventory`.
2. `inventoryStore.ts`: Zustand `useInventoryStore` with `inventory: InventoryView | null`, `selectedUid: number | null`, `setInventory(view)` (also clears `selectedUid` when that uid is no longer in `bag` or `gear`), `select(uid: number | null)`.
3. `rarity.ts`: `export type Rarity = 'issued' | 'common' | 'rare' | 'epic'`; `rarityOf(value: number): Rarity` (`<= 0` issued, `< 250` common, `< 600` rare, else epic); `RARITY_TILE: Record<Rarity, string>` = Tailwind gradient classes: issued `bg-gradient-to-b from-zinc-600/70 to-zinc-800/80`, common `from-emerald-600/70 to-emerald-900/80`, rare `from-violet-600/70 to-violet-900/80`, epic `from-amber-500/70 to-amber-800/80` (each prefixed `bg-gradient-to-b`). `rarity.test.ts`: `0 -> issued`, `249 -> common`, `250 -> rare`, `599 -> rare`, `600 -> epic`.
4. `layout.ts` (CSS px, 1280x720 base):
   ```ts
   export const TILE = 50            // bag slot size
   export const GAP = 1
   export const TITLE = { left: 26, top: 26 }
   export const TABS = { left: 26, top: 96 }
   export const DETAILS = { left: 80, top: 155, width: 405, height: 470 }
   export const BAG = { left: 700, top: 155 }          // width = 6 * TILE + 5 * GAP
   export const EQUIPMENT = { left: 1017, top: 155, width: 183 }
   export const FOOTER_HEIGHT = 36
   ```
5. Components (all `export function`):
   - `KeyHint({ k, label })`: key chip `grid h-6 min-w-6 place-items-center rounded-sm bg-white/90 px-1 text-[11px] font-bold text-zinc-900` + label `text-xs font-semibold uppercase tracking-wider`.
   - `PanelHeader({ title, right })`: `flex h-[33px] items-center justify-between bg-zinc-800/90 px-3`: title `text-lg font-bold uppercase tracking-wide`, optional right text `text-sm font-semibold text-white/80`.
   - `ItemTile({ item, size, selected, onSelect, emptyLabel })`: a `<button type="button">` of `size` = `{ w, h }` px (inline style). With an item: rarity gradient class, `aria-label={item.label}`, label `absolute left-1 top-1 text-[10px] font-semibold leading-tight` (line-clamp 2), value `absolute bottom-0.5 right-1 text-[11px] font-bold` (`formatMoney`, hidden when value is 0), `ring-2 ring-amber-400` when selected, `onClick={() => onSelect(item.uid)}`. Without an item: `bg-zinc-800/50`, `aria-label={emptyLabel ?? 'Empty slot'}`, disabled, shows `emptyLabel` (`text-[10px] uppercase text-white/25`) or a `×` (`text-white/15 text-lg`).
   - `BagGrid({ items, slots, selectedUid, onSelect })`: CSS grid `grid-cols-6` with `gap: GAP`, slot `i < items.length` -> `ItemTile` of the item, else empty tile; size `TILE x TILE`.
   - `EquipmentPanel({ gear, selectedUid, onSelect })`: column `gap-1`: `PanelHeader` `EQUIPMENT`; slot list `PRIMARY` (183x87), `SECONDARY` (183x87), then a row `ARMOR` (90x88) + `BAG` (90x88); then a label `POUCH` (`text-sm font-bold uppercase mt-2`) and a 2x2 grid of `TILE` slots `POUCH`; `gear[i]` fills slot `i` in that order (8 slots); empty slots use `emptyLabel` = the slot name.
   - `DetailsPanel({ item })`: `PanelHeader` `DETAILS`; body `bg-zinc-900/70 p-4`: no item -> `Select an item` (`text-sm text-white/50`); item -> a 120x120 rarity tile (not a button), `text-xl font-bold` label, `formatMoney(value)`, a source chip (`BAG`/`GEAR`, uppercase) and the rarity name (uppercase, `text-xs text-white/60`).
6. `InventoryScreen.tsx`: `export function InventoryScreen()`; reads `inventory`, `selectedUid`, `select` from `useInventoryStore`; returns `null` when `inventory` is null. Root: `pointer-events-auto fixed inset-0 bg-zinc-950/85 text-white`. Absolutely positioned (inline styles from `layout.ts`):
   - Title `INVENTORY` (`text-[44px] font-black uppercase leading-none tracking-tight`) at `TITLE`.
   - Tabs at `TABS`: one active tab `BAG` (`h-[27px] w-[132px] grid place-items-center bg-amber-400 text-zinc-900 text-sm font-bold uppercase`).
   - Cash chip top-right (`right: 80, top: 26`): `rounded bg-zinc-800/90 px-3 py-1 text-lg font-bold` `formatMoney(cash)`.
   - `DetailsPanel` at `DETAILS` with the selected item (find `selectedUid` in `bag` then `gear`).
   - `BAG` panel at `BAG`: `PanelHeader` `BAG` with right text `formatMoney(bagValue)`, then `BagGrid` (`slots = bagSlots`), `mt-1`.
   - `EquipmentPanel` at `EQUIPMENT`.
   - Footer: `absolute inset-x-0 bottom-0 flex items-center gap-8 bg-zinc-900/95 px-[30px]`, height `FOOTER_HEIGHT`: a `<button type="button">` wrapping `KeyHint k="ESC" label="Back"` that calls `void request('inventory.close', {})`, then `KeyHint k="TAB" label="Close"`, `KeyHint k="LMB" label="Select"`.
7. `demoInventory.ts`: `DEMO_INVENTORY: InventoryView` with cash 79900, 8 bag items (values 0, 120, 300, 300, 450, 800, 1500, 60; ids/labels like `jewelry`/`Jewelry`, `electronics`, `cash_box`, `gold_bar`, `painting`, `lockpick`, `drill`, `phone`), `bagValue` = their sum, `bagSlots` 36, gear `cop_pistol`, `cop_radio`, `cop_vest` (value 0, source gear).
8. `router.tsx`: add `/inventory` route with `InventoryScreen`. `HudScreen` already hides the interact card on any non-`/` route; also hide the whole HUD under the inventory: in `app/router.tsx` root component render `HudScreen` only when the path is not `/inventory` (use `useRouterState` inside a small `RootLayout` component in `router.tsx`).
9. `main.tsx`: `installBridge` deps add `setInventory: (v) => useInventoryStore.getState().setInventory(v)`; dev preview: when `window.location.hash === '#inventory'` set `DEMO_INVENTORY` and navigate to `/inventory`.
10. `InventoryScreen.test.tsx` (Testing Library; `vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))`; reset the store in `beforeEach`):
    - null store renders nothing.
    - with `DEMO_INVENTORY`: shows `INVENTORY`, `$79,900`, the bag value; `getAllByRole('button', { name: 'Empty slot' })` has length 28 (36 bag slots - 8 items; equipment empties are named by their slot, not `Empty slot`); `queryByRole('button', { name: 'SECONDARY' })` is null because gear fills it (`Cop radio`); `getByRole('button', { name: 'BAG' })` exists (4th equipment slot is empty: 3 gear items fill PRIMARY, SECONDARY, ARMOR); `getAllByRole('button', { name: 'POUCH' })` has length 4.
    - clicking `getByRole('button', { name: 'Jewelry' })` shows the label in the details panel (two `Jewelry` texts) and the tile gets `ring-amber-400`.
    - clicking the `Back` button calls `request` with `('inventory.close', {})`.
    - `Select an item` is shown before any click.
11. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No Godot files. No item actions (drop/use/move). No new packages. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files created/changed, test summary lines, build output list, any step you could not do and why.
