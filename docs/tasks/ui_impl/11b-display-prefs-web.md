# ui_impl 11b: page-side display preferences (UI scale, colorblind tints, compass, minimap rotation)

Design source: `docs/ui-design/03-settings.md` section 4 rows `ui_scale` ("Expose 90-110%. Apply to adjustable text/chrome within pinned minimap and inventory geometry"), `colorblind_mode` ("Remap optional status tints. Text, markers and shapes remain present every mode"), `show_compass`, `minimap_rotate` ("Counter-rotate Godot minimap view with heading. Keep player arrow forward"). Web only; card 11 (Godot) runs later and makes Godot publish the `settings` snapshot at startup and after every change, and rotates the Godot minimap camera. Read first: `ui/web/src/main.tsx`, `ui/web/src/app/uiScale.ts` (+ its test), `ui/web/src/styles/index.css`, `ui/web/src/features/hud/HudScreen.tsx`, `ui/web/src/features/hud/components/MinimapFrame.tsx`, `ui/web/src/features/hud/components/Compass.tsx`, `ui/web/src/features/settings/settingsStore.ts`, `ui/web/src/features/settings/demoSettings.ts`, `ui/web/src/lib/ipc/protocol.ts` (`SettingsView.values`).

## Decisions for this card (supervisor)
- Features never import each other, so the HUD cannot read the settings store. A new lib store holds the four page preferences; `main.tsx` (app layer) feeds it from every `settings` snapshot:
  - `ui/web/src/lib/prefs.ts`: `export type Colorblind = 'off' | 'protanopia' | 'deuteranopia' | 'tritanopia'`, `export interface Prefs { uiScale: number; colorblind: Colorblind; showCompass: boolean; minimapRotate: boolean }`, `export const DEFAULT_PREFS: Prefs = { uiScale: 100, colorblind: 'off', showCompass: true, minimapRotate: false }`, `export const usePrefs = create<Prefs>(() => DEFAULT_PREFS)`, `export function prefsFromValues(values: Record<string, unknown>): Prefs` (reads `ui_scale` (integer 90..110, else 100), `colorblind_mode` (one of the four, else `'off'`), `show_compass` (boolean, else true), `minimap_rotate` (boolean, else false)).
- UI scale keeps the existing CSS `zoom` (window width / 1280) and adds the setting through the root font size: `html { font-size: 16px * uiScale / 100 }`. Tailwind text sizes and spacing are rem-based, so text and chrome grow; layout boxes placed in px (HUD `layout.ts`, the `box()` helpers, the grids) stay pinned. Pinned geometry must not use rem-based sizes: check `features/hud/components/MinimapFrame.tsx`, `lib/grid/` and `features/inventory/` (+ `features/search/`) for rem-based width/height/position utilities (`w-48`, `h-12`, `top-28`, `gap-2` between grid cells...) on the minimap frame and the grid cells/containers; convert only those to px arbitrary values (`w-[192px]`) with the same rendered size at 100%. Text inside may stay rem. Report what you converted.
- Colorblind mode sets `document.documentElement.dataset.colorblind` (removed for `'off'`) and `styles/index.css` overrides the Tailwind palette variables used as status tints (Okabe-Ito colours). Do not touch `--color-amber-*` (primary buttons, focus ring):
  - protanopia and deuteranopia: `--color-emerald-400: #56b4e9; --color-red-400: #e69f00; --color-red-500: #d55e00; --color-red-600: #d55e00; --color-sky-400: #0072b2;`
  - tritanopia: `--color-emerald-400: #009e73; --color-red-400: #d55e00; --color-red-500: #d55e00; --color-red-600: #d55e00; --color-sky-400: #cc79a7;`
  - Selector `html[data-colorblind='<mode>']` (beats Tailwind's `:root` theme block on specificity). `# ponytail:` comment: rarity tile gradients keep their hex colours (the value text stays).
- Compass: hidden when `showCompass` is false. Minimap arrow: when `minimapRotate` is true the arrow stays pointing up (`rotate(0deg)`; Godot turns the map instead), else it rotates by `heading` as today.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages.
- Host notes: run npm from PowerShell in `d:\FinalRun\ui\web` (Git Bash's `D:/` path breaks vitest); npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; do not start a Vite dev server; `ui/dist/assets` is not readable for you. Do not edit Godot files.

## Files
- create: `ui/web/src/lib/prefs.ts`, `ui/web/src/lib/prefs.test.ts`
- modify: `ui/web/src/app/uiScale.ts` (+ `uiScale.test.ts`), `ui/web/src/main.tsx`, `ui/web/src/styles/index.css`, `ui/web/src/features/hud/HudScreen.tsx`, `ui/web/src/features/hud/components/MinimapFrame.tsx`, the HUD test that covers the compass/minimap (`features/hud/HudScreen.test.tsx`), and only the pinned-geometry files you must convert (list them)

## Steps
1. `lib/prefs.ts` as decided. `prefs.test.ts`: defaults for `{}`; valid values pass through; out-of-range `ui_scale` 150 -> 100; unknown `colorblind_mode` -> `'off'`; non-boolean `show_compass` -> true.
2. `app/uiScale.ts`: keep `uiScale(innerWidth)` and `applyUiScale()`; add `export function rootFontPx(percent: number): number` (`16 * percent / 100`) and `export function applyPrefs(prefs: Prefs): void` (sets `document.documentElement.style.fontSize = \`${rootFontPx(prefs.uiScale)}px\``; sets or deletes `document.documentElement.dataset.colorblind`). Tests: `rootFontPx(110)` = 17.6, `rootFontPx(90)` = 14.4; `applyPrefs` with `colorblind: 'tritanopia'` sets the data attribute and with `'off'` removes it; font size string for 110.
3. `main.tsx`: one `onSettings(view)` function = `useSettingsStore.getState().setView(view); usePrefs.setState(prefsFromValues(view.values))`, used by the bridge `setSettings` and by the `#settings` dev preview; `applyPrefs(usePrefs.getState())` at startup and `usePrefs.subscribe(applyPrefs)`.
4. `styles/index.css`: the three colorblind blocks as decided.
5. `HudScreen.tsx`: `const { showCompass, minimapRotate } = usePrefs()` (or two selectors); render `Compass` only when `showCompass`; pass `heading={minimapRotate ? 0 : hud.heading}` to `MinimapFrame` (or a `rotate` prop; keep `MinimapFrame` free of store access).
6. Pinned geometry check and conversions as decided.
7. Tests: `HudScreen.test.tsx`: with `usePrefs.setState({ ...DEFAULT_PREFS, showCompass: false })` the compass is absent; with `minimapRotate: true` and a HUD heading of 90 the minimap arrow transform is `rotate(0deg)`; reset `usePrefs` to `DEFAULT_PREFS` after each test.
8. Checks: `npm run test`, `npm run build` (in `ui/web/`, from PowerShell).

## Do not
- No Godot files. No settings screen changes. Do not edit `docs/ui-design/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files created/changed, the pinned-geometry conversions (file: before -> after), web test summary line, build output list, anything you could not do and why.
