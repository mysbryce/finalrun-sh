# ui_impl 13b: HUD refine on the page (safe zone line, heist alert, surrender hint, downed channels)

Design source: `docs/ui-design/04-hud.md`: section 2 wireframes "Live HUD", "Downed HUD", "Direct surrender availability" (A08 Heist alert, A16 Surrender hint), section 3 layout tables for those drawings (use their exact x/y/w/h for the new elements) and the layout paragraph about the heist line and toast tray, section 4 rows "Safety", "Heist alert", "Notifications" and the "Downed" and "Surrender" bullets, section 8 accessibility, Decisions 2-5 and 7; `docs/ui-design/DATA_CONTRACTS.md` `HudState`, `HeistAlertView`, `DownedChannels`. Web only; card 13 makes Godot send these fields. Read first: `ui/web/src/features/hud/` (`HudScreen.tsx`, `layout.ts`, `components/*`, `demoHud.ts`, tests), `ui/web/src/lib/ipc/protocol.ts`, `ui/web/src/lib/ui/KeyHint.tsx`, `ui/web/src/lib/ui/ProgressBar.tsx`.

## Decisions for this card (supervisor)
- `protocol.ts`: add `surrenderKey?: string` to `HudState` (label of the bound surrender key from Godot, e.g. `H`; `—` when unbound). The other four optional fields already exist.
- Safety: exact copy `SAFE ZONE - weapons locked` shown when `weaponsLocked === true`; hidden when false or absent. Place it where the Live HUD layout puts the safety line (read the table; if no explicit row exists, put it in the role/status column under the role line and report the position you chose).
- Heist alert: when `heistAlert` is non-null and `active`, show the dedicated alert line (A08) with `label` and `location` (`Heist alert · <location>`, or just the label when location is null). When `toastSecondsLeft > 0`, also show one toast row in the notification tray with the same text, above the ordinary notifications, for that many seconds counted down locally from the snapshot value (dedupe by `id`: a new snapshot with the same id does not restart the toast; a new id does). Max four tray rows total: the heist toast takes one, ordinary notifications fill the rest.
- Surrender hint (A16): shown only when `surrenderAvailable === true` (Godot already limits it to an ALIVE Criminal); `KeyHint` with `surrenderKey ?? 'H'` and the label `Surrender`. Hidden when false or absent.
- Downed channels (Downed HUD drawing): with `life === 'DOWNED'`:
  - `channels.revive` non-null -> `Being revived` with a determinate `ProgressBar` (`durationSeconds - secondsLeft` of `durationSeconds`) and `<secondsLeft> s`.
  - `channels.finish` non-null -> warning `Finish in progress` (danger tint, text + icon/shape, not colour alone).
  - `channels` present and `finish` null -> `At risk of being finished` (neutral warning text).
  - `channels` absent/undefined (old snapshot) -> show `—` in that slot and await the next snapshot.
  - The existing bleed-out banner stays.
- Accessibility: new texts are real text (not images); the heist line and the finish warning use `role="status"` / `aria-live="polite"`; colour is never the only signal.
- `demoHud.ts`: add sample values so the dev preview shows all four (weaponsLocked false in the default demo, plus a heist alert with `toastSecondsLeft: 8`).

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages. Px geometry from `layout.ts` (pinned under UI scale); text may be rem.
- Host notes: run npm from PowerShell in `d:\FinalRun\ui\web` (Git Bash's `D:/` path breaks vitest); npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; do not start a Vite dev server; `ui/dist/assets` is not readable for you. Do not edit Godot files (another worker edits them in parallel).

## Files
- create: new components under `ui/web/src/features/hud/components/` as needed (e.g. `SafetyLine.tsx`, `HeistAlert.tsx`, `SurrenderHint.tsx`, `DownedChannels.tsx`) with tests
- modify: `ui/web/src/lib/ipc/protocol.ts`, `ui/web/src/features/hud/HudScreen.tsx`, `ui/web/src/features/hud/layout.ts`, `ui/web/src/features/hud/components/NotificationStack.tsx` (heist toast row), `ui/web/src/features/hud/demoHud.ts`, `ui/web/src/features/hud/HudScreen.test.tsx`

## Steps
1. `protocol.ts`: `surrenderKey?: string`.
2. Components and layout positions as decided.
3. `HudScreen.tsx`: render them; keep existing behaviour for old snapshots (all four absent -> nothing new shown, no crash).
4. Tests: safety line shown/hidden; heist line with location and without; heist toast counts down (fake timers) and is not restarted by a snapshot with the same id, restarted by a new id; tray never exceeds four rows with a toast plus four notifications; surrender hint shows `H Surrender` and the bound label (`F`), hidden when false; downed: revive progress text `3 s` for `secondsLeft: 3`, `Finish in progress`, `At risk of being finished`, `—` for absent `channels`; an old snapshot without the new fields renders.
5. Checks: `npm run test`, `npm run build` (in `ui/web/`, from PowerShell).

## Do not
- No Godot files. Do not edit `docs/ui-design/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files created/changed, positions used for each new element (and where the spec gave none), web test summary line, build output list, anything you could not do and why.
