# inventory_ui 09: drag overlay follows the cursor under page zoom (web)

Bug (owner report): while dragging a bag item, the floating tile (`DragOverlay`) is not under the cursor; it drifts further away the further the item is from the top-left of the page.

Cause: `app/uiScale.ts` sets `document.documentElement.style.zoom = innerWidth / 1280`. `DragOverlay` is `position: fixed` at the dragged node's rect (`getBoundingClientRect`, already in zoomed screen px) plus a `translate3d` of the pointer delta (screen px). Inside the zoomed `<html>` both are multiplied by the zoom again, so the overlay lands at `(left + delta) * zoom` instead of `left + delta`.

Fix: a dnd-kit modifier on the `DragOverlay` that cancels the zoom. Only touch `ui/web/` and `ui/dist/`.

## Rules
- `ui/web/src/`: a feature never imports `app/`; same-folder `./`, cross-folder `@/`; `import type` for types. No new packages.
- Host notes: npm `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'`. Leave the Vite dev server on 5173 running.

## Files
- create: `src/features/inventory/dragZoom.ts`, `src/features/inventory/dragZoom.test.ts`
- modify: `src/features/inventory/InventoryScreen.tsx`
- rebuild: `ui/dist/**`

## Steps
1. `dragZoom.ts`:
   ```ts
   import type { Modifier } from '@dnd-kit/core'

   // The page zoom set on <html> by app/uiScale.ts (1 when unset).
   export function pageZoom(): number {
     const z = Number.parseFloat(document.documentElement.style.zoom)
     return Number.isFinite(z) && z > 0 ? z : 1
   }

   // DragOverlay is position: fixed at `left/top` (screen px) plus the transform, and
   // the zoomed <html> scales both again. Returns the transform that puts the overlay
   // at (left + x, top + y) on screen.
   export function unzoom(
     t: { x: number; y: number; scaleX: number; scaleY: number },
     rect: { left: number; top: number } | null,
     zoom: number,
   ) {
     if (!rect || zoom === 1) return t
     return { ...t, x: (rect.left + t.x) / zoom - rect.left, y: (rect.top + t.y) / zoom - rect.top }
   }

   export const unzoomModifier: Modifier = ({ transform, activeNodeRect }) =>
     unzoom(transform, activeNodeRect, pageZoom())
   ```
2. `dragZoom.test.ts`: `unzoom` with zoom 1 returns the same object; with zoom 1.5, rect `{left: 600, top: 300}` and `t = {x: 30, y: -60, scaleX: 1, scaleY: 1}` gives `x = 630 / 1.5 - 600 = -180`, `y = 240 / 1.5 - 300 = -140`, scale unchanged; rect `null` returns `t`. `pageZoom()`: set `document.documentElement.style.zoom = '1.5'` -> 1.5; set it to `''` -> 1 (reset it after the test).
3. `InventoryScreen.tsx`: `<DragOverlay modifiers={[unzoomModifier]}>` (import from `./dragZoom`). Nothing else changes.
4. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- Do not change `app/uiScale.ts` or how the page is zoomed. No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files changed/created, test summary lines, build output list, any step you could not do and why.
