# cef_ui 03: one `ui/` folder for all UI, clear source vs build, feature-based web `src/`

Pure restructure. No behavior change: same IPC, same HUD look, same tests (moved).

## Target layout (exact)
```
ui/
  hud/Hud.gd                     # Godot side (unchanged)
  web/                           # web project source (was webui/), has .gdignore
    .gdignore
    index.html  package.json  package-lock.json  tsconfig.json  vite.config.ts
    src/
      main.tsx                   # entry: installs the bridge, renders <App />
      vite-env.d.ts
      app/
        App.tsx                  # providers: QueryClientProvider + RouterProvider
        router.tsx               # TanStack Router (memory history), route tree
        queryClient.ts           # TanStack Query client
      lib/
        ipc/
          protocol.ts            # HudState, HudTimer, GodotToPage, PageToGodot (was types.ts)
          bridge.ts              # send, request, handleMessage, installBridge
          bridge.test.ts
      features/
        hud/
          HudScreen.tsx          # route component, lays out the widgets
          hudStore.ts            # useHudStore (was store.ts)
          components/
            StatusPanel.tsx      # role badge, life, money line
            TimerBanner.tsx
            NotificationStack.tsx
            InteractPrompt.tsx
      styles/
        index.css
  dist/                          # build output (was ui/web/), generated, committed
```
Dependency rule (same as the Godot side): `app/ -> features/ -> lib/`. `lib/` imports nothing from `features/` or `app/`. One feature does not import another feature's files.

## Host notes (this sandbox)
- npm's default cache is outside the workspace: pass `--cache <your session temp dir>\npm-cache` to any `npm install` / `npm ci`.
- Keep `pool: 'threads'` in the vitest config (forks cannot spawn here).

## Steps
1. Delete the old build output folder `ui/web/` (only `index.html` and `assets/`; regenerated in step 10).
2. Move the whole folder `webui/` to `ui/web/` (PowerShell `Move-Item webui ui/web`, includes `node_modules`). If moving `node_modules` fails, delete it and run `npm ci` in `ui/web/`.
3. `ui/web/vite.config.ts`:
   - `build.outDir`: `'../ui/web'` -> `'../dist'`. Keep everything else (`emptyOutDir: true`, `base: './'`, `server`, `test` with `pool: 'threads'`).
   - Add the `@` alias: `import { fileURLToPath, URL } from 'node:url'` and `resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } }`.
   - If `tsc` cannot resolve `node:url`, run `npm install -D @types/node` (with the cache flag) and add `"node"` to nothing else; the types are picked up from `vite.config.ts` being in `include`.
4. `ui/web/tsconfig.json`: add `"paths": { "@/*": ["./src/*"] }` to `compilerOptions`. Do not add `baseUrl`.
5. Move files inside `ui/web/src/` (content unchanged except imports):
   - `router.tsx` -> `app/router.tsx`; `queryClient.ts` -> `app/queryClient.ts`
   - `types.ts` -> `lib/ipc/protocol.ts`; `bridge.ts` -> `lib/ipc/bridge.ts`; `bridge.test.ts` -> `lib/ipc/bridge.test.ts`
   - `store.ts` -> `features/hud/hudStore.ts`
   - `index.css` -> `styles/index.css`
   - `main.tsx`, `vite-env.d.ts` stay.
6. Create `app/App.tsx`: `export function App()` returning `<QueryClientProvider client={queryClient}><RouterProvider router={router} /></QueryClientProvider>`. `main.tsx` keeps the `installBridge(...)` call and renders `<StrictMode><App /></StrictMode>`.
7. Split `src/hud/Hud.tsx` into `features/hud/`, then delete `src/hud/`:
   - `components/StatusPanel.tsx`: `export function StatusPanel({ hud }: { hud: HudState })`: the top-left panel with the same classes; `roleColor` and `lifeColor` move here (only user).
   - `components/TimerBanner.tsx`: `export function TimerBanner({ timer }: { timer: HudTimer })`: the top-center banner, same classes.
   - `components/NotificationStack.tsx`: `export function NotificationStack({ items }: { items: string[] })`: the top-right stack, same classes.
   - `components/InteractPrompt.tsx`: `export function InteractPrompt({ text }: { text: string })`: the bottom-center pill, same classes.
   - `HudScreen.tsx`: `export function HudScreen()`: reads `hud` from `useHudStore`, returns `null` when `hud` is null, else the same root `div` as the old `Hud` (`pointer-events-none fixed inset-0`) containing `<StatusPanel hud={hud} />`, `{hud.timer !== null && <TimerBanner timer={hud.timer} />}`, `<NotificationStack items={hud.notifications} />`, `{hud.prompt !== '' && <InteractPrompt text={hud.prompt} />}`.
8. Imports: use the `@/` alias for every cross-folder import (`@/lib/ipc/protocol`, `@/features/hud/hudStore`, `@/app/router`, ...); `./` only for files in the same folder. Use `import type` for type-only imports. `app/router.tsx` uses `HudScreen` as the `/` route component.
9. `lib/constants/GameConst.gd`: `UI_PAGE_URL` -> `"res://ui/dist/index.html"`, comment `# built web UI (ui/web/ -> ui/dist/)`.
10. In `ui/web/`: `npm run test`, then `npm run build`. Check `ui/dist/index.html` exists with `./assets/` paths, and that `webui/` and `ui/web/assets/` no longer exist.

## Do not
- No behavior change: same Tailwind classes, IPC messages, test assertions. Do not touch `ui/hud/Hud.gd`, `main/`, docs, or `.gitignore` (the supervisor updates them). Do not run git.

## Done when
- `npm run test` and `npm run build` (in `ui/web/`) pass.
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: the final file tree of `ui/` (without `node_modules`), the test summary lines, the build output file list, any step you could not do and why.
