# inventory_ui 02: component tests for the web UI (Testing Library + jsdom)

Owner request: add component tests. Only touch `ui/web/` (no rebuild of `ui/dist/` needed: no runtime code changes).

## Rules
- Host notes: npm needs `--cache <session temp dir>\npm-cache`; vitest keeps `pool: 'threads'` and `environment: 'jsdom'`.
- Tests live next to the component: `Foo.tsx` -> `Foo.test.tsx`. Import from `vitest` explicitly (no globals). Query by visible text or role, not by class names, except where a test checks a state that is only visible as a class (active slot ring, health fill width): then assert on that one class / style.

## Files
- modify: `ui/web/package.json`, `ui/web/package-lock.json` (dev deps), `ui/web/vite.config.ts`
- create: `ui/web/src/test/setup.ts`
- create: `ui/web/src/features/hud/components/Hotbar.test.tsx`, `HealthBar.test.tsx`, `InteractCard.test.tsx`, `PartyPanel.test.tsx`, `StatusColumn.test.tsx`, `ui/web/src/features/hud/HudScreen.test.tsx`

## Steps
1. In `ui/web/`: `npm install -D @testing-library/react @testing-library/dom @testing-library/jest-dom` (with the cache flag).
2. `src/test/setup.ts`:
   ```ts
   import '@testing-library/jest-dom/vitest'
   import { cleanup } from '@testing-library/react'
   import { afterEach } from 'vitest'

   afterEach(() => cleanup())
   ```
   `vite.config.ts`: `test: { environment: 'jsdom', pool: 'threads', setupFiles: ['./src/test/setup.ts'] }`.
3. Read each component before writing its test (props are in the files). Tests:
   - `Hotbar.test.tsx`: render with `slots=[{label:'Pistol'}, null, null, null, null, null]`, `active=0`, `bag=500`: shows `Pistol`, keys `1`..`6`, `TAB`, and `$500`; the box containing `Pistol` has class `ring-amber-400`; empty slots render `×` five times.
   - `HealthBar.test.tsx`: `health=50 maxHealth=100 away=false`: the fill elements (children with an inline `width`) are `100%, 100%, 0%, 0%`; `health=20`: first fill has class `bg-red-500`; `away=true`: all widths `0%`.
   - `InteractCard.test.tsx`: `{title:'Loot crate', actions:[{key:'E',label:'lockpick'},{key:'V',label:'smash'}]}` shows `Loot crate`, `E`, `lockpick`, `V`, `smash`; with `title:''` the title is not rendered; an action with `key:''` renders no key chip (only the label).
   - `PartyPanel.test.tsx`: party `[{name:'Player 3',health:100,maxHealth:100,life:'ALIVE',leader:true,away:false},{name:'Player 4',health:-1,maxHealth:100,life:'?',leader:false,away:true}]`, self `{name:'Player 2'}`, health 75: shows all three names and exactly one `AWAY`.
   - `StatusColumn.test.tsx`: build a full `HudState` (copy `DEMO_HUD` from `../demoHud` and override): with `timer {label:'Masking', seconds:65}` and life `ALIVE` shows `MASKING 1:05`, role text and `NOTORIETY 500`; with life `DOWNED` the timer pill is not shown.
   - `HudScreen.test.tsx`: before each test reset the store (`useHudStore.setState({ hud: null })`). With `hud` null it renders nothing (`container` is empty). After `useHudStore.setState({ hud: DEMO_HUD })` it shows the cash (`formatMoney(DEMO_HUD.cash)`), `Player 2` and the interact title. HudScreen calls `useRouterState`, so render it inside a router: create a test router with `createRouter({ routeTree: createRootRoute({ component: HudScreen }), history: createMemoryHistory({ initialEntries: ['/'] }) })` and render `<RouterProvider router={router} />`; use `await screen.findByText(...)` for the first assertion (router renders async).
4. Run `npm run test` (all old and new tests) and `npm run build` (type check must stay clean).

## Do not
- No changes to components or other source files (if a test cannot pass without a source change, stop and report it). Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: installed dev dependency versions, files created, the test summary lines, any step you could not do and why.
