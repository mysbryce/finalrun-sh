# inventory_ui 08: match the reference layout and proportions (web)

Design: `docs/design/INVENTORY_UI.md` ("Reference structure", "Visual measurements"). Runs after card 07. Only touch `ui/web/` and `ui/dist/`.

## Rules
- Copy the reference's **structure and proportions** (positions, sizes, gaps, tile tints, footer chips). Never its distinctive look: no italic, no condensed font, no lime/green-yellow accent, no watermark title, no diagonal slash art, no icons or images. Accent stays `amber-400`. System font stays.
- All numbers are CSS px on the 1280x720 base (`app/uiScale.ts` zooms the page). Put every position/size in `layout.ts`, not inline magic numbers in components.
- `ui/web/src/`: same-folder `./`, cross-folder `@/`; `import type` for types. No new packages.
- Host notes: npm `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'`. Leave the Vite dev server on 5173 running.

## Context (read first)
`src/features/inventory/`: `layout.ts`, `rarity.ts` (+ test), `InventoryScreen.tsx` (+ test), `components/{ItemTile, PanelHeader, BagGrid, EquipmentPanel, DetailsPanel, KeyHint}.tsx`.

## Files
- modify: `src/features/inventory/layout.ts`, `rarity.ts`, `rarity.test.ts` (only if a class assertion breaks), `InventoryScreen.tsx`, `InventoryScreen.test.tsx`, `components/ItemTile.tsx`, `components/PanelHeader.tsx`, `components/EquipmentPanel.tsx`, `components/DetailsPanel.tsx`, `components/KeyHint.tsx`
- rebuild: `ui/dist/**`

## Steps
1. `layout.ts` (keep `TILE`, `GAP`, `BAG_COLUMNS`, `PITCH`, `cellBox`, `FOOTER_HEIGHT = 36`); set:
   ```ts
   export const TITLE = { left: 25, top: 32 }
   export const TABS = { left: 25, top: 95, width: 132, height: 27 }
   export const CASH = { right: 23, top: 29, height: 25 }
   export const PANEL_TOP = 155
   export const HEADER_HEIGHT = 33
   export const HEADER_GAP = 11            // header bar -> panel content
   export const BAG_ROWS = 9
   export const BAG_GRID = { width: BAG_COLUMNS * TILE + (BAG_COLUMNS - 1) * GAP, height: BAG_ROWS * TILE + (BAG_ROWS - 1) * GAP } // 305 x 458
   export const DETAILS = { left: 80, top: PANEL_TOP, width: 405 }
   export const BAG = { left: 701, top: PANEL_TOP }
   export const EQUIPMENT = { left: 1017, top: PANEL_TOP, width: 183, wide: { w: 183, h: 88 }, square: { w: 88, h: 88 }, gap: 7, pouch: { w: 72, h: 101 }, pouchGap: 11 }
   ```
   Remove the old `DETAILS.height` and any constant nothing uses any more.
2. `InventoryScreen.tsx`:
   - Root background: `pointer-events-auto fixed inset-0 bg-gradient-to-br from-[#3b3b3b]/95 via-[#303030]/95 to-[#262626]/95 text-white`.
   - Title at `TITLE`: unchanged classes (`text-[44px] font-black uppercase leading-none tracking-tight`).
   - Tab at `TABS` (size from `TABS.width/height`), same active classes.
   - Cash chip: `absolute`, `right: CASH.right, top: CASH.top, height: CASH.height`, classes `flex items-center rounded-sm bg-black/40 px-2 text-sm font-bold`.
   - BAG panel at `BAG`: `PanelHeader` with width `BAG_GRID.width`, then the grid wrapper `style={{ marginTop: HEADER_GAP }}` (replace `mt-1`).
   - Details panel at `DETAILS` with `width`.
   - Footer: `absolute inset-x-0 bottom-0 flex items-center gap-8 bg-[#1b1b1b] px-[30px]`, height `FOOTER_HEIGHT`. The `Back` button gets `flex h-[22px] items-center rounded-sm bg-white/10 px-2`.
3. `PanelHeader.tsx`: `flex items-center justify-between bg-black/25 px-2.5`, height `HEADER_HEIGHT` (inline style from `layout.ts`); optional prop `width?: number` (inline style). Title and right text classes unchanged.
4. `DetailsPanel.tsx`: body `style={{ marginTop: HEADER_GAP, height: BAG_GRID.height }}` with `bg-black/20 p-4` (replace `bg-zinc-900/70`); content unchanged.
5. `ItemTile.tsx`:
   - Empty tile: `bg-black/25` (replace `bg-zinc-800/50`). With `emptyLabel`: unchanged text. Without: replace the `×` text with an inline SVG cross `aria-hidden="true"`, `width={26} height={26} viewBox="0 0 26 26"`, two lines `(1,1)-(25,25)` and `(25,1)-(1,25)`, `stroke="currentColor" strokeWidth={1.5}`, class `text-white/15`. When the tile is smaller than 30 px in either side keep the same SVG (it is 26 px).
   - New optional prop `emptyName?: string`: `aria-label={emptyLabel ?? emptyName ?? 'Empty slot'}` (shows the cross, not text).
   - Value text: add `drop-shadow-[0_1px_1px_rgba(0,0,0,0.8)]`. Label unchanged.
6. `rarity.ts` `RARITY_TILE` (bright at the bottom like the reference):
   - issued `bg-gradient-to-t from-[#4d4d4d] to-[#2e2e2e]`
   - common `bg-gradient-to-t from-[#557a43] to-[#273822]`
   - rare `bg-gradient-to-t from-[#7a4f9a] to-[#352640]`
   - epic `bg-gradient-to-t from-[#a8922a] to-[#4a4114]`
7. `EquipmentPanel.tsx`:
   - Column with `PanelHeader title="EQUIPMENT"` then content `style={{ marginTop: HEADER_GAP }}`, slots separated by `EQUIPMENT.gap`.
   - `SLOTS = ['PRIMARY', 'SECONDARY', 'ARMOR', 'BAG', 'POUCH', 'POCKET', 'POCKET', 'POCKET', 'POCKET']`; `gear[i]` fills slot `i`.
   - PRIMARY, SECONDARY: `EQUIPMENT.wide`. Row: ARMOR + BAG: `EQUIPMENT.square`, gap `EQUIPMENT.gap`.
   - Label `POUCH` (`text-sm font-bold uppercase`, `marginTop: 8`, `marginBottom: 6`).
   - Pouch row: `flex`, gap `EQUIPMENT.pouchGap`: slot 4 (`POUCH`, `emptyLabel`) at `EQUIPMENT.pouch`; then a 2x2 grid (`gap: GAP`, width `2 * TILE + GAP`) of slots 5-8 at `TILE x TILE` using `emptyName="Pocket"` (no `emptyLabel`, so they show the cross).
8. `KeyHint.tsx`: key chip `grid h-4 min-w-4 place-items-center rounded-[2px] border border-white/70 px-1 text-[10px] font-bold leading-none` (outlined, no white fill); label `text-[11px] font-semibold uppercase tracking-wider`.
9. `InventoryScreen.test.tsx`: `Empty slot` stays 33; `POUCH` button count becomes 1; add `getAllByRole('button', { name: 'Pocket' })` length 4; other assertions unchanged (fix only what the new markup breaks, never weaken a check).
10. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No behaviour changes (drag, select, close). No new tabs or fake buttons. No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files changed, test summary lines, build output list, any step you could not do and why.
