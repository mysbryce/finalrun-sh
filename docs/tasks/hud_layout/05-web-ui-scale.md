# hud_layout 05: scale the web UI with the game's canvas stretch

## Failing behavior (seen in a 1600x900 windowed client)
The Godot minimap is drawn at screen (30, 50), size 250x212, but the web frame is at (24, 40), size 200x170: they do not line up.

## Cause
`project.godot` uses `window/stretch/mode="canvas_items"` with a 1280x720 base, so Godot canvas units are scaled by `window width / 1280` (1.25 at 1600 px). The CEF page renders at physical pixels (1 CSS px = 1 screen px, `window.innerWidth` = 1600), so the page does not scale.

## Fix
Zoom the whole page by `window.innerWidth / 1280`. Then 1 CSS px = 1 Godot canvas unit at any window size, and the HUD grows with the resolution like the rest of the game UI.

## Files
- create: `ui/web/src/app/uiScale.ts`, `ui/web/src/app/uiScale.test.ts`
- modify: `ui/web/src/main.tsx`
- modify: `docs/design/WEB_UI.md`
- rebuild: `ui/dist/**`

## Steps
1. `ui/web/src/app/uiScale.ts`:
   ```ts
   // Must match project.godot window/size/viewport_width (canvas_items stretch base).
   export const BASE_WIDTH = 1280

   // 1 CSS px = 1 Godot canvas unit: zoom the page like Godot scales its canvas.
   export function uiScale(innerWidth: number): number {
     return innerWidth > 0 ? innerWidth / BASE_WIDTH : 1
   }

   export function applyUiScale(): void {
     document.documentElement.style.zoom = String(uiScale(window.innerWidth))
   }
   ```
2. `ui/web/src/app/uiScale.test.ts` (vitest): `uiScale(1600) === 1.25`, `uiScale(1280) === 1`, `uiScale(0) === 1`; after setting `window.innerWidth` to 1920 (`Object.defineProperty(window, 'innerWidth', { value: 1920, configurable: true })`) and calling `applyUiScale()`, `document.documentElement.style.zoom === '1.5'`.
3. `ui/web/src/main.tsx`: import `applyUiScale` from `@/app/uiScale`; before `installBridge(...)` call `applyUiScale()` and add `window.addEventListener('resize', applyUiScale)`.
4. `docs/design/WEB_UI.md`, section "Input", add a new section after it:
   ```
   ## Scale
   Godot stretches its canvas (`canvas_items`, base 1280x720); CEF renders the page at physical pixels. `app/uiScale.ts` zooms the page by `innerWidth / 1280`, so 1 CSS px = 1 Godot canvas unit at every window size. Rects shared by both sides (the minimap) use the same numbers on both sides.
   ```
5. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No other changes. No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files changed, test summary lines, build output list.
