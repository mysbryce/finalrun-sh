# Web UI (Godot CEF + React)

Owner decision 2026-11-27: the game UI is HTML rendered by the Godot CEF addon, built with React + Zustand + Tailwind, plus TanStack Router, Query and Virtual where they fit.

## Pieces
- **Addon:** `addons/godot_cef` (dsh0416/godot-cef v2.2.0, MIT, Godot 4.6+). Config files are committed; native binaries in `addons/godot_cef/bin/` are gitignored and installed with `tools/install_godot_cef.ps1`.
- **Source:** `ui/web/` (Vite + React + TypeScript). It has a `.gdignore`, so Godot never scans it (`node_modules` would otherwise be imported).
- **Build output:** `ui/dist/` (`npm run build` in `ui/web/`). Godot loads `res://ui/dist/index.html` into one full-screen `CefTexture`. The build is committed so the game runs without Node; never hand-edit it.
- **Godot side:** `ui/hud/Hud.gd` (`class_name Hud`, `CanvasLayer`) owns the `CefTexture`, turns game state into JSON messages, and answers UI requests. It is created only on clients with a display (`DisplayServer.get_name() != "headless"` and `ClassDB.class_exists("CefTexture")`). The server and headless tests never create a browser.
- **Dev mode:** the client started with `-- --ui-dev` loads `GameConst.UI_DEV_URL` (`http://localhost:5173/`, the Vite dev server with hot reload) instead of the built page.

## Source layout (`ui/web/src/`)
Same shape and dependency rule as the Godot side: `app/ -> features/ -> lib/`. `lib/` never imports `features/` or `app/`; a feature never imports another feature's files. Cross-folder imports use the `@/` alias.
```
main.tsx                  entry: installs the bridge, renders <App />
app/                      App.tsx (providers), router.tsx (route tree), queryClient.ts
lib/ipc/                  protocol.ts (message and HudState types), bridge.ts (+ bridge.test.ts)
features/<screen>/        <Screen>Screen.tsx (route component), <screen>Store.ts, components/
styles/index.css          Tailwind entry
```
A new screen adds `features/<screen>/`, one route in `app/router.tsx`, and its request methods to the table below.

## Which tool for what
| Need | Tool |
|---|---|
| State Godot pushes (HUD numbers, role, timers, prompt, notifications) | Zustand store, replaced by each `hud` message |
| Screens/panels (HUD, later: body search, party, shop, inventory) | TanStack Router, memory history; Godot switches screens with `route` messages |
| Actions and data the UI asks Godot for (request/response: `search.take` mutations, later shop catalog queries) | TanStack Query (`useMutation` / `useQuery`) over `bridge.request(method, params)` |
| Panel data Godot pushes (search contents) | Zustand store per feature, replaced by each push message |
| Long lists (search items, inventory, shop catalog, notification log) | TanStack Virtual |
| Styling | Tailwind v4 (`@tailwindcss/vite`) |

## IPC protocol
All messages are JSON strings. Godot sends with `CefTexture.send_ipc_message(JSON.stringify(msg))`; the page receives them in `window.onIpcMessage(text)`. The page sends with `window.sendIpcMessage(JSON.stringify(msg))`; Godot receives them on the `ipc_message(message: String)` signal.

Godot to page:
| `type` | Fields | Meaning |
|---|---|---|
| `hud` | `data: HudState` | Full HUD snapshot. Sent only when it changed. |
| `route` | `to: string` | Navigate to a route (`"/"` = HUD only, `"/search"` = body search panel over the HUD). |
| `search` | `data: SearchView \| null` | Open body search contents (resent on every change), `null` when it closed. |
| `reply` | `id: number`, `ok: boolean`, `data?: unknown`, `error?: string` | Answer to a page `request`. |

`HudState`: see `docs/design/HUD_LAYOUT.md` ("HudState v2").

`SearchView`:
```json
{"target": 7, "title": "Body of Player 7",
 "items": [{"uid": 12, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear"}]}
```

Page to Godot:
| `type` | Fields | Meaning |
|---|---|---|
| `ready` | none | Page loaded. Godot replies with the current `route`, the open `search` (if any) and the `hud` snapshot. |
| `request` | `id: number`, `method: string`, `params: object` | Ask Godot for data. Godot always answers with one `reply` carrying the same `id`. Unknown method: `ok: false`, `error: "unknown_method"`. |

Methods (Godot only forwards them; the server validates every action):
| Method | Params | Reply `data` | Effect |
|---|---|---|---|
| `ping` | none | `{"pong": true}` | none |
| `search.take` | `{target, uid}` | `{}` | `ServerManager.request_search_take(target, uid)`. Error `no_search` when `target` is not the open search, `bad_params` when `uid <= 0`. |
| `search.close` | `{target}` | `{}` | `ServerManager.request_search_close(target)`. Error `no_search` as above. |

`ui/` never calls `ServerManager`: `Hud` emits `search_take_requested` / `search_close_requested` and `main/Main.gd` connects them. A reply `ok: true` means "forwarded", not "taken": the result arrives as a new `search` message and a notification.

## Input
The HUD is display-only: the `CefTexture` uses `mouse_filter = MOUSE_FILTER_IGNORE` and `focus_mode = FOCUS_NONE`, so mouse and keys reach the game. Interactive panels (body search) switch the `CefTexture` to `MOUSE_FILTER_STOP` and set `Input.mouse_mode = MOUSE_MODE_VISIBLE` while open, then back to `IGNORE` and `CAPTURED` on close. Keys stay with the game (`Q` closes the search).

## Scale
Godot stretches its canvas (`canvas_items`, base 1280x720); CEF renders the page at physical pixels. `app/uiScale.ts` zooms the page by `innerWidth / 1280`, so 1 CSS px = 1 Godot canvas unit at every window size. Rects shared by both sides (the minimap) use the same numbers on both sides.

## Open items
- Export: Godot export must include `ui/dist/*` as non-resource files (export filter), checked when export is set up.
- Remote DevTools is on by default (port 9229). Turn it off for release builds (`godot_cef/debug/remote_devtools_port`).
- Visual theme: neutral placeholder until the owner picks one.
