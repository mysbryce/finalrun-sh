# search_panel 03: hide the interact card while a panel is open

## Failing behavior (dev preview `http://localhost:5173/#search`)
The HUD interact card ("LOOT CRATE", `[E] lockpick`, `[V] smash`) shows through the body search panel: the panel background is translucent (`bg-zinc-950/80`) and the card sits at the same screen spot.

## Fix
1. `ui/web/src/features/hud/HudScreen.tsx`: `import { useRouterState } from '@tanstack/react-router'`; `const panelOpen = useRouterState({ select: (s) => s.location.pathname !== '/' })` (call it before the `if (!hud) return null` line, hooks must not be conditional). Render `InteractCard` only when `hud.interact && !panelOpen`.
2. `ui/web/src/features/search/SearchScreen.tsx`: panel background `bg-zinc-950/80` -> `bg-zinc-950/95`.
3. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No other changes. Only `ui/web/` and `ui/dist/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass. Final answer: the two changed lines, test summary lines, build output list.
