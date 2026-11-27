# search_panel 02: body search panel on the web UI (Router + Zustand + Query mutation + Virtual)

Design: `docs/design/WEB_UI.md` (IPC `search` message, `search.take` / `search.close` methods, "Which tool for what") and `docs/design/HUD_LAYOUT.md` ("Visual style"). Card 01 does the Godot side in parallel; only touch `ui/web/` and `ui/dist/`.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; `lib/` never imports `features/`; a feature never imports another feature's files; cross-folder imports `@/`, same-folder `./`; `import type` for types.
- Display and requests only: the server decides what is taken.
- Visual style: panels `bg-zinc-950/60 rounded-md ring-1 ring-white/10` (panel body may use `/80`), white text, accent `amber-400`, uppercase `font-semibold tracking-wider` labels, system font.
- Host notes: npm needs `--cache <session temp dir>\npm-cache`; vitest keeps `pool: 'threads'`. No new packages (`@tanstack/react-virtual` and `@tanstack/react-query` are installed).

## Protocol (copy)
- Godot -> page: `{"type":"search","data": SearchView | null}`; `SearchView = { target: number; title: string; items: SearchItem[] }`; `SearchItem = { uid: number; id: string; label: string; value: number; source: string }` (`source` is `"bag"` or `"gear"`).
- Godot -> page `{"type":"route","to":"/search"}` opens the panel, `"/"` closes it.
- Page -> Godot requests: `request('search.take', { target, uid })`, `request('search.close', { target })`; reply data `{}`; errors `no_search`, `bad_params`. A successful reply only means "forwarded": the list updates through the next `search` message.

## Files
- move: `ui/web/src/features/hud/format.ts` -> `ui/web/src/lib/format.ts`, `format.test.ts` -> `ui/web/src/lib/format.test.ts` (now used by two features); fix imports in `features/hud/components/CashBox.tsx`, `Hotbar.tsx`, `StatusColumn.tsx` to `@/lib/format`.
- modify: `ui/web/src/lib/ipc/protocol.ts`, `ui/web/src/lib/ipc/bridge.ts`, `ui/web/src/lib/ipc/bridge.test.ts`
- create: `ui/web/src/features/search/searchStore.ts`, `ui/web/src/features/search/SearchScreen.tsx`, `ui/web/src/features/search/components/SearchItemRow.tsx`, `ui/web/src/features/search/demoSearch.ts`
- modify: `ui/web/src/app/router.tsx`, `ui/web/src/main.tsx`
- rebuild: `ui/dist/**`

## Steps
1. Move `format.ts` and `format.test.ts` to `lib/` as listed; update the three imports. Contents unchanged.
2. `lib/ipc/protocol.ts`: add `SearchItem` and `SearchView` (shapes above); add `| { type: 'search'; data: SearchView | null }` to `GodotToPage`.
3. `lib/ipc/bridge.ts`: `BridgeDeps` gets `setSearch: (view: SearchView | null) => void`; `handleMessage` case `'search'` -> `deps.setSearch((message.data ?? null) as SearchView | null)`.
4. `lib/ipc/bridge.test.ts`: `makeDeps()` adds `setSearch: vi.fn()`; new test `search message calls setSearch` (one with a view, one with `data: null` -> called with `null`).
5. `features/search/searchStore.ts`: Zustand `useSearchStore` with `search: SearchView | null` (initial `null`) and `setSearch(view: SearchView | null)`.
6. `features/search/components/SearchItemRow.tsx`: `export function SearchItemRow({ item, pending, onTake }: { item: SearchItem; pending: boolean; onTake: () => void })`: a `flex h-12 items-center gap-3 px-3 border-b border-white/5` row: label (`text-sm font-semibold flex-1 truncate`), source chip (`text-[10px] uppercase tracking-wider rounded px-1.5 py-0.5`, `bg-amber-500/20 text-amber-300` for `bag`, `bg-white/10 text-white/70` otherwise), value `formatMoney(item.value)` (`text-sm w-20 text-right`), and a `TAKE` button (`pointer-events-auto rounded-sm bg-amber-400 px-3 py-1 text-xs font-bold text-zinc-900 hover:bg-amber-300 disabled:opacity-40`, `disabled={pending}`, `onClick={onTake}`).
7. `features/search/SearchScreen.tsx`: `export function SearchScreen()`:
   - `const search = useSearchStore((s) => s.search)`; return `null` when null.
   - `const take = useMutation({ mutationFn: (uid: number) => request('search.take', { target: search.target, uid }) })` (`useMutation` from `@tanstack/react-query`, `request` from `@/lib/ipc/bridge`). `pending` for a row = `take.isPending && take.variables === item.uid`.
   - `const close = () => { void request('search.close', { target: search.target }) }`.
   - Virtual list: `const parentRef = useRef<HTMLDivElement>(null)`; `const rows = useVirtualizer({ count: search.items.length, getScrollElement: () => parentRef.current, estimateSize: () => 48, overscan: 6 })` (`@tanstack/react-virtual`). Scroll container `ref={parentRef}` `className="h-[336px] overflow-y-auto"`, inner `div` `style={{ height: rows.getTotalSize(), position: 'relative' }}`, each virtual row absolutely positioned (`top: 0, left: 0, width: '100%', height: row.size, transform: translateY(row.start px)`) rendering `SearchItemRow` with `key={item.uid}`.
   - Layout: `pointer-events-auto absolute left-1/2 top-1/2 w-[460px] -translate-x-1/2 -translate-y-1/2 rounded-md bg-zinc-950/80 ring-1 ring-white/10 text-white`. Header `flex items-center justify-between px-4 py-3 border-b border-white/10`: title (`text-lg font-bold uppercase tracking-wider`) and on the right `{n} ITEMS` (`text-[11px] text-white/60`) plus a close button `×` (`h-7 w-7 rounded-sm bg-white/10 hover:bg-white/20`, `onClick={close}`). Empty list: a `px-4 py-10 text-center text-sm text-white/60` line `Nothing left to take`. Footer `flex gap-4 px-4 py-2 border-t border-white/10 text-[11px] text-white/60`: key chip `Q` + `CLOSE` (same chip style as the HUD interact card: `grid h-5 w-5 place-items-center rounded-sm bg-white text-[10px] font-bold text-zinc-900`).
   - When `take.isError`, show `take.error.message` in a `px-4 pb-2 text-xs text-red-400` line.
8. `features/search/demoSearch.ts`: `export const DEMO_SEARCH: SearchView` with target 7, title `"Body of Player 7"`, 40 items (generate: `Array.from({ length: 40 }, (_, i) => ({ uid: i + 1, id: \`item_${i + 1}\`, label: \`Item ${i + 1}\`, value: (i + 1) * 50, source: i % 3 === 0 ? 'gear' : 'bag' }))`).
9. `app/router.tsx`: root component renders the HUD under every route: `component: () => (<><HudScreen /><Outlet /></>)`; the `/` route component becomes `() => null`; add `searchRoute = createRoute({ getParentRoute: () => rootRoute, path: '/search', component: SearchScreen })`; `routeTree: rootRoute.addChildren([hudRoute, searchRoute])`.
10. `main.tsx`: `installBridge` deps add `setSearch: (v) => useSearchStore.getState().setSearch(v)`. In the dev preview block (`import.meta.env.DEV && !window.sendIpcMessage`): also, when `window.location.hash === '#search'`, call `useSearchStore.getState().setSearch(DEMO_SEARCH)` and `void router.navigate({ to: '/search' })`.
11. In `ui/web/`: `npm run test`, then `npm run build`.

## Do not
- No Godot files. No new packages. Do not run git.

## Done when
- `npm run test` and `npm run build` in `ui/web/` pass.
- Final answer: files created/moved/changed, test summary lines, build output list, any step you could not do and why.
