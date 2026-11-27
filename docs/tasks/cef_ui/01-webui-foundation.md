# cef_ui 01: web UI foundation (Vite + React + TS + Zustand + Tailwind + TanStack Router/Query) and the HUD page

Design: `docs/design/WEB_UI.md` (rules copied below). Card 02 does the Godot side in parallel; do not touch any Godot file.

## Rules (from docs/design/WEB_UI.md and docs/CONVENTIONS.md)
- Source lives in `webui/`; build output goes to `ui/web/` (Godot loads `res://ui/web/index.html` in a Chromium view). All asset paths in the build must be relative (`./assets/...`), never `/assets/...`.
- `webui/.gdignore` must exist (empty file) so Godot never scans `webui/` or `node_modules`.
- The web UI only displays state and sends requests. No game rules in it.
- IPC: all messages are JSON strings. Godot -> page arrives in `window.onIpcMessage(text: string)`. Page -> Godot is `window.sendIpcMessage(text: string)`. Both globals come from the browser host; in a plain browser (dev) `sendIpcMessage` may be missing, then sending is a no-op with `console.debug`.
- Godot -> page messages:
  - `{"type":"hud","data":HudState}`
  - `{"type":"route","to":string}` (navigate; `"/"` is the HUD)
  - `{"type":"reply","id":number,"ok":boolean,"data"?:unknown,"error"?:string}`
- Page -> Godot messages:
  - `{"type":"ready"}` once after the bridge is installed.
  - `{"type":"request","id":number,"method":string,"params":object}`; Godot answers with exactly one `reply` with the same `id`.
- `HudState` = `{ role: string, life: string, cash: number, bag: number, notoriety: number, timer: { label: string, seconds: number } | null, prompt: string, notifications: string[] }`.

## Files
- create: `webui/.gdignore` (empty)
- create: `webui/package.json`, `webui/package-lock.json` (from npm), `webui/vite.config.ts`, `webui/tsconfig.json`, `webui/index.html`
- create: `webui/src/index.css`, `webui/src/types.ts`, `webui/src/store.ts`, `webui/src/bridge.ts`, `webui/src/queryClient.ts`, `webui/src/router.tsx`, `webui/src/main.tsx`, `webui/src/hud/Hud.tsx`
- create: `webui/src/bridge.test.ts`
- create (build output): `ui/web/**`

## Steps
1. In `webui/`, create `package.json`:
   ```json
   {
     "name": "finalrun-webui",
     "private": true,
     "type": "module",
     "scripts": {
       "dev": "vite",
       "build": "tsc --noEmit && vite build",
       "test": "vitest run"
     }
   }
   ```
   Then run in `webui/`:
   `npm install react react-dom zustand @tanstack/react-router @tanstack/react-query @tanstack/react-virtual`
   `npm install -D vite @vitejs/plugin-react typescript @types/react @types/react-dom tailwindcss @tailwindcss/vite vitest jsdom`
   (Let npm pick the latest versions. Do not use `npm create`.)
2. `webui/vite.config.ts`:
   ```ts
   import { defineConfig } from 'vite'
   import react from '@vitejs/plugin-react'
   import tailwindcss from '@tailwindcss/vite'

   export default defineConfig({
     plugins: [react(), tailwindcss()],
     base: './',
     build: { outDir: '../ui/web', emptyOutDir: true },
     server: { port: 5173, strictPort: true },
     test: { environment: 'jsdom' },
   })
   ```
   Add `/// <reference types="vitest/config" />` as the first line if TypeScript complains about `test`.
3. `webui/tsconfig.json`: `compilerOptions` = `target "ES2022"`, `lib ["ES2022","DOM","DOM.Iterable"]`, `module "ESNext"`, `moduleResolution "bundler"`, `jsx "react-jsx"`, `strict true`, `noEmit true`, `skipLibCheck true`, `isolatedModules true`, `types ["vitest/globals"]` is NOT needed (import from `vitest` explicitly). `include ["src", "vite.config.ts"]`.
4. `webui/index.html`: standard Vite page, `<title>FinalRun UI</title>`, `<div id="root"></div>`, `<script type="module" src="/src/main.tsx"></script>` (Vite rewrites it to a relative path because of `base: './'`).
5. `webui/src/index.css`:
   ```css
   @import "tailwindcss";
   html, body, #root { margin: 0; height: 100%; background: transparent; overflow: hidden; user-select: none; }
   ```
6. `webui/src/types.ts`: export `HudTimer`, `HudState` (shape above), `GodotToPage` (discriminated union of `hud` / `route` / `reply`), `PageToGodot` (union of `ready` / `request`).
7. `webui/src/store.ts`: Zustand store `useHudStore` with `hud: HudState | null` (initial `null`) and `setHud(hud: HudState): void`.
8. `webui/src/bridge.ts`:
   - `declare global { interface Window { onIpcMessage?: (text: string) => void; sendIpcMessage?: (text: string) => void } }`
   - `export function send(msg: PageToGodot): void`: `window.sendIpcMessage` present -> call it with `JSON.stringify(msg)`; else `console.debug('[bridge] no host', msg)`.
   - Module-level `let nextId = 1` and `const pending = new Map<number, { resolve: (v: unknown) => void; reject: (e: Error) => void; timer: ReturnType<typeof setTimeout> }>()`.
   - `export function request<T>(method: string, params: Record<string, unknown> = {}, timeoutMs = 5000): Promise<T>`: take `id = nextId++`, store resolver, start a timer that rejects with `new Error('timeout')` and deletes the entry, then `send({ type: 'request', id, method, params })`.
   - `export type BridgeDeps = { setHud: (hud: HudState) => void; navigate: (to: string) => void }`.
   - `export function handleMessage(text: string, deps: BridgeDeps): void`: `JSON.parse` in try/catch (bad JSON -> `console.warn` and return). Then:
     - `hud` -> `deps.setHud(msg.data)`
     - `route` -> `deps.navigate(msg.to)`
     - `reply` -> look up `pending.get(msg.id)`; if found: clear its timer, delete it, then `ok` -> `resolve(msg.data)`, else `reject(new Error(msg.error ?? 'request_failed'))`. Unknown id: ignore.
     - anything else: ignore.
   - `export function installBridge(deps: BridgeDeps): void`: `window.onIpcMessage = (text) => handleMessage(text, deps)`, then `send({ type: 'ready' })`.
9. `webui/src/queryClient.ts`: `export const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: 0, refetchOnWindowFocus: false } } })`.
10. `webui/src/router.tsx` (code-based routes, no file-based plugin):
    - `rootRoute = createRootRoute({ component: () => <Outlet /> })`
    - `hudRoute = createRoute({ getParentRoute: () => rootRoute, path: '/', component: Hud })`
    - `export const router = createRouter({ routeTree: rootRoute.addChildren([hudRoute]), history: createMemoryHistory({ initialEntries: ['/'] }) })`
    - `declare module '@tanstack/react-router' { interface Register { router: typeof router } }`
11. `webui/src/main.tsx`: import `./index.css`; `installBridge({ setHud: (h) => useHudStore.getState().setHud(h), navigate: (to) => { void router.navigate({ to }) } })`; render `<StrictMode><QueryClientProvider client={queryClient}><RouterProvider router={router} /></QueryClientProvider></StrictMode>` into `#root`.
12. `webui/src/hud/Hud.tsx` (display only, no clicks, `pointer-events-none` on the root):
    - Read `hud` from `useHudStore`; render nothing when `null`.
    - Top-left panel (`rounded-xl bg-black/55 px-4 py-3 text-white`): a role badge (CITIZEN `bg-zinc-500`, CRIMINAL `bg-red-600`, COP `bg-blue-600`, else `bg-zinc-700`) with the role text, then the life text (DOWNED `text-amber-400`, DEAD `text-red-400`, else `text-emerald-400`). Second line: `Cash $<cash> · Bag $<bag> · Notoriety <notoriety>` (numbers with `toLocaleString('en-US')`).
    - Top-center banner when `timer` is not null: `<label>: <seconds> s`, large text (`text-2xl font-bold`), amber background for `Bleeding out`, otherwise red.
    - Top-right stack: each notification in its own small pill (`bg-black/60 rounded-lg px-3 py-1`), newest last.
    - Bottom-center pill with `prompt` when it is not empty.
13. `webui/src/bridge.test.ts` (vitest, `import { describe, it, expect, vi } from 'vitest'`):
    - `hud message calls setHud`: `handleMessage(JSON.stringify({type:'hud', data: sample}), deps)` -> `setHud` called with `sample`.
    - `route message navigates`: `{type:'route', to:'/'}` -> `navigate('/')`.
    - `bad json is ignored`: `handleMessage('{oops', deps)` does not throw and calls nothing.
    - `request resolves on ok reply`: set `window.sendIpcMessage = vi.fn()`; `const p = request('ping')`; read the sent id from `JSON.parse(window.sendIpcMessage.mock.calls[0][0]).id`; `handleMessage(JSON.stringify({type:'reply', id, ok:true, data:{pong:true}}), deps)`; `await expect(p).resolves.toEqual({pong:true})`.
    - `request rejects on error reply`: same with `ok:false, error:'unknown_method'` -> rejects with message `unknown_method`.
    - `installBridge sends ready`: after `installBridge(deps)`, `window.sendIpcMessage` was called with `JSON.stringify({type:'ready'})`.
14. Run `npm run test` and `npm run build` in `webui/`. Check that `ui/web/index.html` exists and its script/link tags use `./assets/` paths.

## Do not
- Do not touch anything outside `webui/` and `ui/web/`. No other routes, no Query hooks yet, no Virtual usage yet (installed for the next panels). No images or SVG assets. Do not run git.

## Done when
- `npm run test` (in `webui/`) passes.
- `npm run build` (in `webui/`) succeeds and `ui/web/index.html` references `./assets/...`.
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` warning lines are harmless noise).
- Final answer: files created, the installed package versions (from `package.json`), the test summary line, the build output file list, any step you could not do and why.
