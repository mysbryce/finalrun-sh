# ui_impl 16b: notoriety only for Criminals; party picker placeholder and peer id (web)

Found in the step 14 desktop smoke:
- The HUD shows `NOTORIETY 0` for a Citizen. `docs/ui-design/04-hud.md` "Role and life visibility matrix": Notoriety is shown only for "Criminal alive" (hidden for Citizen, Cop, Downed Criminal, Downed Cop).
- The Pause party picker is blank when other players exist and none is selected (`Dropdown` shows `current?.label ?? ''`). The pause wireframe (`docs/ui-design/wireframes/04-pause.svg`) labels picker entries "Display name · peer ID", and `docs/ui-design/DATA_CONTRACTS.md` says the picker shows name and peer to disambiguate; today it shows the name only.

Read first: `ui/web/src/features/hud/components/StatusColumn.tsx` (+ test), `ui/web/src/lib/ui/Dropdown.tsx`, `ui/web/src/features/pause/PartyPanel.tsx` (+ test).

## Decisions for this card (supervisor)
- `StatusColumn`: render the notoriety chip only when `hud.role === 'CRIMINAL' && hud.life !== 'DOWNED'`. Comment: `04-hud.md` visibility matrix.
- `Dropdown`: new optional prop `placeholder?: string`. The trigger's value span (keep its `id`) shows `current?.label ?? placeholder ?? ''`; when the placeholder is the shown text, add `text-zinc-400` to that span. No other behaviour change.
- `PartyPanel`: pass `placeholder="Choose a player"`; player option labels become `` `${p.name} · ${p.peerId}` `` (U+00B7 middle dot with a space on each side). The "No other players" option stays as is.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages.
- Host notes: run npm from PowerShell in `d:\FinalRun\ui\web` (Git Bash's `D:/` path breaks vitest); npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; do not start a Vite dev server; `ui/dist/assets` is not readable for you. Do not edit Godot files.

## Files
- modify: `ui/web/src/features/hud/components/StatusColumn.tsx`, `ui/web/src/features/hud/components/StatusColumn.test.tsx`, `ui/web/src/lib/ui/Dropdown.tsx`, `ui/web/src/features/pause/PartyPanel.tsx`, `ui/web/src/features/pause/PartyPanel.test.tsx`

## Steps
1. `StatusColumn` condition.
2. `Dropdown` placeholder prop.
3. `PartyPanel` placeholder and option labels.
4. Tests:
   - `StatusColumn.test.tsx`: the existing alive test keeps `role: 'CRIMINAL'` explicitly and still sees `NOTORIETY 500`; new: `role: 'CITIZEN'`, `life: 'ALIVE'` -> no text matching `/NOTORIETY/`; new: `role: 'CRIMINAL'`, `life: 'DOWNED'` -> no `/NOTORIETY/`.
   - `PartyPanel.test.tsx`: update the option name `'Player 9'` to `'Player 9 · 9'`; new: with players and nothing selected, `getByRole('button', { name: /Invite player/ })` has text content `Choose a player`.
5. Checks: `npm run test`, `npm run build` (in `ui/web/`, from PowerShell).

## Do not
- No Godot files. Do not edit `docs/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files changed, web test summary line, build output list, anything you could not do and why.
