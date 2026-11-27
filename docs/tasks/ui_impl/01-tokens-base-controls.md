# ui_impl 01: UI tokens and base controls in `lib/ui`

Design source: `docs/ui-design/tokens.md` and `docs/ui-design/components.md` (read both; this card implements the listed parts only). README "Implementation order" steps 1-2. Web only, no Godot changes.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; a feature never imports another feature; `lib/` never imports `features/`; same-folder `./`, cross-folder `@/`; `import type` for types. No new npm packages.
- Visual language: system font stack, upright text, zinc surfaces, `amber-400` is the only accent. Sizes are base CSS px (the page is zoomed from 1280 px by `app/uiScale.ts`; do not fight it).
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest runs with `pool: 'threads'` (already configured). Leave the Vite dev server on 5173 running.

## Files
- modify: `ui/web/src/styles/index.css`, `ui/web/src/features/inventory/InventoryScreen.tsx` (KeyHint import only)
- create: `ui/web/src/lib/ui/contrast.ts` + `contrast.test.ts`, `Button.tsx`, `Panel.tsx`, `HeaderBar.tsx`, `KeyHint.tsx`, `ProgressBar.tsx`, `Modal.tsx`, and one `ui.test.tsx` covering the components
- delete: `ui/web/src/features/inventory/components/KeyHint.tsx` (moved)

## Steps
1. `styles/index.css` (keep the existing two lines):
   - `@theme { --font-sans: system-ui, -apple-system, "Segoe UI", sans-serif; }`
   - `@utility focus-ring { outline: 2px solid var(--color-amber-400); outline-offset: 2px; }` (used as `focus-visible:focus-ring`; the 2 px offset shows the zinc-950/zinc-900 surface behind it).
   - `@media (prefers-reduced-motion: reduce) { *, ::before, ::after { transition-duration: 0ms !important; animation-duration: 0ms !important; } }`
   - `html` gets `font-family: var(--font-sans)` and `font-variant-numeric: normal`; add a `.tabular { font-variant-numeric: tabular-nums; }` rule (timers, currency, health).
2. `lib/ui/contrast.ts`: `export function contrastRatio(fg: string, bg: string): number` (WCAG 2 relative luminance from `#rrggbb`). `contrast.test.ts`: the pairs from tokens.md hold: zinc-100 `#f4f4f5` on zinc-900 `#18181b` >= 15, zinc-300 `#d4d4d8` on zinc-800 `#27272a` >= 9, zinc-900 on amber-400 `#fbbf24` >= 9, and every body pair >= 4.5; black on white = 21.
3. `KeyHint.tsx`: move the inventory component unchanged in markup, API `{ k: string; label: string }`, plus an optional `binding?: string | null` override: when `binding === null` render the text `Unbound` in the chip. Chip height 20 px (`h-5`), min width 20, 4 px horizontal inset, caption 11 px. Update the inventory import to `@/lib/ui/KeyHint`.
4. `Button.tsx`: `{ label: string; variant?: 'primary' | 'secondary' | 'quiet' | 'destructive'; size?: 'default' | 'compact'; disabled?: boolean; loading?: boolean; onPress?: () => void; describedBy?: string; type?: 'button' | 'submit' }`. Height 40 (compact 36), `min-w-[88px]`, px 16, radius 4, 14/20 600. Primary `bg-amber-400 text-zinc-900`; secondary `bg-zinc-800 border border-zinc-500 text-zinc-100`; quiet `text-zinc-300` no border; destructive like secondary (neutral, the label carries the verb). Hover lifts fill (`hover:brightness-110` or one step lighter), active `active:translate-y-px`, `focus-visible:focus-ring`, transitions 80 ms. `disabled` or `loading` -> `disabled` attribute, keep the label; `loading` adds `aria-busy="true"` and ignores presses.
5. `Panel.tsx`: `{ title?: string; children; inset?: number (default 16); busy?: boolean; className?: string; style?: CSSProperties }` -> `<section aria-label={title} aria-busy={busy}>` with `bg-zinc-900 rounded-md` (6 px), padding = inset. Busy keeps bounds (render children with `opacity-60`).
6. `HeaderBar.tsx`: `{ title: string; subtitle?: string; leading?: ReactNode; trailing?: ReactNode; compact?: boolean }` height 56 (compact 36), `flex items-center gap-3`, title 18/24 650 (`text-lg font-semibold`), subtitle 12/16 zinc-300, `trailing` pushed right.
7. `ProgressBar.tsx`: `{ label: string; value?: number; max: number; size?: 'default' | 'compact'; showValue?: boolean }`. Track 12 px (compact 4) `bg-zinc-800 rounded-sm`, fill amber-400 with width `value/max` clamped 0-1. `role="progressbar"`, `aria-label={label}`, `aria-valuemin=0`, `aria-valuemax={max}`, `aria-valuenow` only when `value` is defined. `value === undefined` = indeterminate: static striped track (no animation) and the visible text `Working`. `showValue` renders `Math.round(100*value/max)%` (tabular) next to it.
8. `Modal.tsx`: `{ title: string; children; primary: { label: string; onPress: () => void; busy?: boolean }; secondary?: { label: string; onPress: () => void }; dismissible?: boolean; onDismiss?: () => void }`.
   - Layer `fixed inset-0 z-60 bg-zinc-950/55`; dialog 512 x 256 at left 384, top 232 (absolute), `bg-zinc-900 rounded-lg` (8 px), 24 px inset, `role="dialog" aria-modal="true" aria-labelledby` the title; actions row bottom-right, buttons from step 4 (secondary first, primary last).
   - Focus: on mount focus the secondary action if present (safest), else the primary; Tab / Shift+Tab cycle inside the dialog; Escape calls `onDismiss` when `dismissible`; on unmount restore focus to the element that was focused before it opened.
   - `primary.busy` -> primary button `loading`.
9. `ui.test.tsx` (Testing Library): Button calls `onPress`, does not when `disabled` or `loading`, has `aria-busy` when loading; KeyHint renders `Unbound` for `binding={null}`; ProgressBar sets `aria-valuenow` for 30/100 and omits it (and shows `Working`) without value; Modal focuses the secondary button on open, Escape calls `onDismiss` only when `dismissible`, Tab from the last button wraps to the first, focus returns to the opener after unmount.
10. In `ui/web/`: `npm run test`, `npm run build`.

## Do not
- No TabBar/Slider/Toggle/Dropdown/Toast yet (next cards). No changes to screens other than the KeyHint import. No Godot files. Do not run git.

## Done when
- `npm run test` and `npm run build` pass (inventory tests still green).
- Final answer: files created/changed/deleted, test summary line, build output list, anything from the design you could not map and why.
