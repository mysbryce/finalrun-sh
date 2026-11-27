# ui_impl 02: form controls (TabBar, Slider, Toggle, Dropdown) and Toast tray in `lib/ui`

Design source: `docs/ui-design/components.md` rows Tab bar, Slider, Toggle, Dropdown, Toast (read them; implement those rows only). Card 01 already added `lib/ui/` (`Button`, `Panel`, `HeaderBar`, `KeyHint`, `ProgressBar`, `Modal`, `contrast`) and the `focus-visible:focus-ring` utility in `styles/index.css`: reuse them, same code style. Web only.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; `lib/` never imports `features/`; same-folder `./`, cross-folder `@/`; `import type` for types. No new npm packages (no headless UI libs: plain React + ARIA).
- Sizes in base CSS px; zinc surfaces, `amber-400` single accent, transitions 80 ms; every focusable control uses `focus-visible:focus-ring`.
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'` is configured. Leave the Vite dev server on 5173 running. `ui/dist/assets` is not readable for you (permission rule); the build result is enough.

## Files
- create in `ui/web/src/lib/ui/`: `TabBar.tsx`, `Slider.tsx`, `Toggle.tsx`, `Dropdown.tsx`, `ToastTray.tsx`, `controls.test.tsx`

## Steps
1. `TabBar.tsx`: `{ tabs: { id: string; label: string; disabled?: boolean; error?: boolean }[]; selectedId: string; onSelect: (id: string) => void; label: string }`. `role="tablist" aria-label={label}`, height 44, equal-width tabs (`flex-1`), each a `button role="tab" aria-selected`, roving tabindex (selected 0, others -1). Selected: 2 px amber-400 underline + zinc-100 text; others zinc-300, hover `bg-zinc-800`. Left/Right arrows move focus and select the previous/next enabled tab (wrap), Home/End first/last enabled; Enter/Space select. Disabled tabs are skipped by arrows and not clickable. `error` appends a visible ` !` marker text with `aria-describedby`-free plain text "(error)" for screen readers (`sr-only`).
2. `Slider.tsx`: `{ label: string; value: number; min: number; max: number; step: number; unit?: string; disabled?: boolean; onChange: (v: number) => void; format?: (v: number) => string }`. Row height 36: visible label (left), 4 px track with amber fill to value and 14 px thumb, 64 px readout (tabular, `format(value)` or `${value}${unit ?? ''}`). Implement as a styled native `<input type="range">` (keyboard and ARIA for free: arrows step, Home/End) plus `aria-valuetext` = the readout; add PageUp/PageDown = ±5 steps (native range does 10% in some browsers; handle `onKeyDown` and clamp). Values snap to `step` and clamp to `[min, max]`. Disabled shows the value, no changes.
3. `Toggle.tsx`: `{ label: string; checked: boolean; onChange: (v: boolean) => void; disabled?: boolean; description?: string }`. `button role="switch" aria-checked`, 36 px hit area containing a 48 x 24 track with 18 px thumb; adjacent visible text `On` / `Off`; Off track zinc-700 thumb zinc-300, On track zinc-800 with amber-400 thumb moved right. Space/Enter toggle (native button). `description` rendered under the label (12/16 zinc-300) and linked via `aria-describedby`.
4. `Dropdown.tsx`: `{ label: string; value: string; options: { value: string; label: string; disabled?: boolean; reason?: string }[]; onChange: (v: string) => void; disabled?: boolean; error?: string }`. Trigger 36 px button (`aria-haspopup="listbox" aria-expanded`) showing the current label and a `▾` mark; menu `role="listbox"` absolutely below the trigger, min width = trigger, `max-h-[224px] overflow-y-auto`, options 32 px `role="option" aria-selected`, `z-40`. Keys on the trigger: ArrowDown/Enter/Space open with the current option active; in the open menu ArrowUp/Down move (skip disabled), Home/End, Enter selects + closes, Escape closes and returns focus to the trigger, typing a letter jumps to the next option starting with it. Click outside closes. Disabled options show `reason` text and cannot be selected. `error` renders under the trigger in red-400 12/16 with `aria-describedby`. Use `aria-activedescendant` on the listbox (focus stays on the listbox element).
5. `ToastTray.tsx`: `{ toasts: { id: string; text: string; priority?: 'normal' | 'high' }[] }` -> presentational tray, `role="status" aria-live="polite"`, toasts 368 x 24 each (one line, truncate), 4 px gap, newest at the bottom, max 4 shown (the last 4), renders nothing when empty. Timing/removal stays with the caller (no timers here; `ponytail:` comment).
6. `controls.test.tsx`: TabBar ArrowRight selects the next enabled tab skipping a disabled one and wraps; Slider PageUp adds 5 steps and clamps at max, readout shows the unit; Toggle click calls `onChange(!checked)` and exposes `aria-checked`; Dropdown opens with ArrowDown, ArrowDown+Enter selects the next enabled option, Escape closes and focuses the trigger, a disabled option cannot be chosen, typing `h` jumps to the first option starting with h; ToastTray shows only the last 4 and nothing when empty.
7. In `ui/web/`: `npm run test`, `npm run build`.

## Do not
- No screens, no store, no IPC changes, no Godot files. Do not touch `docs/ui-design/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files created, test summary line, build output list, design details you could not map and why.
