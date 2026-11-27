# hud_layout 02: web HUD in the reference layout (HudState v2)

Design: `docs/design/HUD_LAYOUT.md` (zones, HudState v2, visual style). Card 01 does the Godot side in parallel; only touch `ui/web/` and `ui/dist/`.

## Rules (from docs/design/WEB_UI.md)
- Web source `ui/web/src/`: `app/ -> features/ -> lib/`; `lib/` never imports `features/`; cross-folder imports use `@/`, same-folder `./`; `import type` for types.
- Display only: no game rules. The HUD root keeps `pointer-events-none fixed inset-0`.
- Host notes: npm needs `--cache <session temp dir>\npm-cache`; vitest keeps `pool: 'threads'`. No new npm packages.
- Own visual style (do not imitate another game's fonts or colors): panels `bg-zinc-950/60 rounded-md ring-1 ring-white/10`, white text, accent `amber-400`, role colors CITIZEN `bg-zinc-500`, CRIMINAL `bg-red-600`, COP `bg-blue-600`. Labels uppercase `font-semibold tracking-wider`. System font.

## Files
- modify: `ui/web/src/lib/ipc/protocol.ts`, `ui/web/src/lib/ipc/bridge.test.ts`, `ui/web/src/main.tsx`
- modify: `ui/web/src/features/hud/HudScreen.tsx`, `ui/web/src/features/hud/components/NotificationStack.tsx`
- delete: `ui/web/src/features/hud/components/StatusPanel.tsx`, `TimerBanner.tsx`, `InteractPrompt.tsx`
- create in `ui/web/src/features/hud/`: `layout.ts`, `format.ts`, `format.test.ts`, `compass.ts`, `compass.test.ts`, `demoHud.ts`
- create in `ui/web/src/features/hud/components/`: `NetStats.tsx`, `MinimapFrame.tsx`, `StatusColumn.tsx`, `Compass.tsx`, `BleedOutBanner.tsx`, `CashBox.tsx`, `HealthBar.tsx`, `PartyPanel.tsx`, `Hotbar.tsx`, `InteractCard.tsx`
- rebuild: `ui/dist/**`

## Steps
1. `lib/ipc/protocol.ts`: replace `HudState` with v2 and add the part types:
   ```ts
   export type HudTimer = { label: string; seconds: number }
   export type InteractAction = { key: string; label: string }
   export type HudInteract = { title: string; actions: InteractAction[] }
   export type PartyMember = { name: string; health: number; maxHealth: number; life: string; leader: boolean; away: boolean }
   export type HotbarSlot = { label: string; count?: number } | null
   export type HudState = {
     role: string; life: string; health: number; maxHealth: number
     cash: number; bag: number; notoriety: number
     heading: number
     timer: HudTimer | null
     interact: HudInteract | null
     notifications: string[]
     self: { name: string }
     party: PartyMember[]
     hotbar: HotbarSlot[]; activeSlot: number
     net: { fps: number; ping: number }
   }
   ```
   Keep `GodotToPage` and `PageToGodot` as they are.
2. `lib/ipc/bridge.test.ts`: update `sample` to the v2 shape (any valid values). No other test change.
3. `features/hud/layout.ts`:
   ```ts
   // Must match GameConst.HUD_MINIMAP_RECT on the Godot side: Godot draws the
   // map texture in this rect under the page; the page only draws the frame.
   export const MINIMAP = { left: 24, top: 40, width: 200, height: 170 } as const
   export const COMPASS_WIDTH = 560
   export const COMPASS_PX_PER_DEG = 4
   ```
4. `features/hud/format.ts`: `formatMoney(n: number): string` -> `'$' + n.toLocaleString('en-US')`; `formatClock(seconds: number): string` -> `m:ss` (`0:02`, `1:05`, `12:00`), negative treated as 0. `format.test.ts`: those cases plus `formatMoney(79900) === '$79,900'`.
5. `features/hud/compass.ts`: `export type CompassMark = { deg: number; offset: number; label: string; major: boolean }`; `export function compassMarks(heading: number, halfSpan = 70, step = 15, pxPerDeg = COMPASS_PX_PER_DEG): CompassMark[]`: for every `d` that is a multiple of `step` with `heading - halfSpan <= d <= heading + halfSpan` (walk from `Math.ceil((heading - halfSpan) / step) * step`), `deg = ((d % 360) + 360) % 360`, `offset = (d - heading) * pxPerDeg`, `major = deg % 45 === 0`, `label` = `['N','NE','E','SE','S','SW','W','NW'][deg / 45]` when major else `String(deg)`. `compass.test.ts`: heading 0 has a mark `{deg 0, offset 0, label 'N', major true}`; heading 90 has offset-0 label `'E'`; heading 0 has a mark with label `'15'` at offset 60; heading 350 has a mark `deg 0, label 'N', offset 40`; heading 10 has a mark `deg 345, label '345'` (wrap below 0).
6. `features/hud/demoHud.ts`: `export const DEMO_HUD: HudState` = the JSON example in `docs/design/HUD_LAYOUT.md` ("HudState v2"), plus a second party member `{ name: 'Player 4', health: -1, maxHealth: 100, life: '?', leader: false, away: true }`.
7. `main.tsx`: after `installBridge(...)`, add: `if (import.meta.env.DEV && !window.sendIpcMessage) useHudStore.getState().setHud(DEMO_HUD)` (browser dev preview without Godot).
8. Components (each `export function X(props)`; Tailwind only; arbitrary values allowed):
   - `NetStats({ fps, ping })`: `absolute left-6 top-3 text-[11px] font-semibold tracking-wider text-white/80`: `FPS {fps} · PING {ping} MS`.
   - `MinimapFrame({ heading })`: absolutely positioned with `style={{ left, top, width, height }}` from `MINIMAP`, `rounded-md ring-2 ring-white/25` and NO background (Godot draws under it). Center: an inline `<svg>` 18x18 triangle arrow (`fill` amber-400, white stroke) rotated with `style={{ transform: \`rotate(${heading}deg)\` }}`, centered with `absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2`.
   - `StatusColumn({ hud })`: `absolute flex flex-col items-start gap-1.5` at `left: MINIMAP.left + MINIMAP.width + 12`, `top: MINIMAP.top`. Rows: timer pill when `hud.timer && hud.life !== 'DOWNED'` (`bg-red-600 rounded px-2 py-0.5 text-sm font-bold`, text `{label.toUpperCase()} {formatClock(seconds)}`); role badge (role color, `text-xs font-bold px-2 py-0.5 rounded`); notoriety chip (panel style, `text-xs`: `NOTORIETY {n}`).
   - `Compass({ heading })`: `absolute left-1/2 top-2 -translate-x-1/2 h-9 overflow-hidden`, width `COMPASS_WIDTH`, `style.maskImage = 'linear-gradient(to right, transparent, black 15%, black 85%, transparent)'`. Each mark absolutely at `left: COMPASS_WIDTH / 2 + offset`, `-translate-x-1/2`, `top-3`; major `text-sm font-bold text-white`, minor `text-[11px] text-white/60`. Center tick: `absolute left-1/2 top-0 h-2.5 w-0.5 -translate-x-1/2 bg-amber-400`.
   - `NotificationStack({ items })`: move to `absolute left-1/2 top-14 -translate-x-1/2 flex flex-col items-center gap-1`; each item panel style `px-3 py-1 text-sm`.
   - `BleedOutBanner({ seconds })`: `absolute left-1/2 top-28 -translate-x-1/2 rounded-md bg-amber-600/90 px-6 py-2 text-3xl font-bold tracking-wider`: `BLEEDING OUT {seconds}`.
   - `CashBox({ cash })`: `absolute right-6 top-4`, panel style, `px-4 py-1.5 text-xl font-bold`: `formatMoney(cash)`.
   - `HealthBar({ health, maxHealth, away })`: `flex h-1.5 gap-[2px]`, 4 segments `flex-1 bg-white/15 overflow-hidden`, inner fill width `clamp(ratio * 4 - i, 0, 1) * 100%` with `ratio = away ? 0 : health / maxHealth`; fill `bg-emerald-400`, or `bg-red-500` when `ratio < 0.3`.
   - `PartyPanel({ party, self, health, maxHealth })`: `absolute left-6 bottom-6 flex w-[280px] flex-col gap-2`. Each member: panel `px-3 py-1.5`; row with a dot (`h-2 w-2 rounded-full`, `bg-amber-400` if leader else `bg-sky-400`), name `text-sm font-semibold`, and `AWAY` (`text-[10px] text-white/50`) when away; then `HealthBar`. Last: self panel `px-3 py-2`, emerald dot, name, `HealthBar`.
   - `Hotbar({ slots, active, bag })`: `absolute right-6 bottom-6 flex items-end gap-1.5`. For each slot index `i`: column with the slot box (`i < 2` -> `w-36 h-16`, else `w-12 h-16`; panel style; `ring-2 ring-amber-400` when `i === active`), slot label `text-xs font-semibold` (or a faint `×` `text-white/20` when null), optional `count` bottom-right `text-[10px]`; under it the key `text-[10px] text-white/60`: `{i + 1}`. Then a `mx-1 h-12 w-px bg-white/20` divider and the bag column: box `w-16 h-16` panel style with `BAG` (`text-[10px]`) and `formatMoney(bag)` (`text-xs font-bold`), key `TAB` under it.
   - `InteractCard({ interact })`: `absolute left-1/2 top-[58%] -translate-x-1/2 flex flex-col items-start gap-1`. Title (when not empty): `bg-zinc-950/70 px-3 py-1 text-lg font-bold uppercase tracking-wider`. Each action row `flex items-center gap-2`: key chip `grid h-6 w-6 place-items-center rounded-sm bg-white text-xs font-bold text-zinc-900` (hidden when key is `''`), label `rounded-sm bg-zinc-950/60 px-3 py-1 text-sm capitalize ring-1 ring-amber-400/80`.
9. `HudScreen.tsx`: keep `useHudStore` and the `null` early return; root `pointer-events-none fixed inset-0 text-white`; render `NetStats`, `MinimapFrame`, `StatusColumn`, `Compass`, `NotificationStack`, `BleedOutBanner` (only when `hud.life === 'DOWNED' && hud.timer`), `CashBox`, `PartyPanel`, `Hotbar`, `InteractCard` (only when `hud.interact`).
10. Delete `StatusPanel.tsx`, `TimerBanner.tsx`, `InteractPrompt.tsx`.
11. In `ui/web/`: `npm run test`, then `npm run build`. Check `ui/dist/index.html` uses `./assets/` paths.

## Do not
- No Godot files. No new packages, routes, Query hooks, images or font files. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files created/changed/deleted, test summary lines, build output list, any step you could not do and why.
