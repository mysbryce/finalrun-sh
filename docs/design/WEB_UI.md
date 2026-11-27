# Web UI (Godot CEF + React)

Owner decision 2026-11-27: the game UI is HTML rendered by the Godot CEF addon, built with React + Zustand + Tailwind, plus TanStack Router, Query and Virtual where they fit.

## Pieces
- **Addon:** `addons/godot_cef` (dsh0416/godot-cef v2.2.0, MIT, Godot 4.6+). Config files are committed; native binaries in `addons/godot_cef/bin/` are gitignored and installed with `tools/install_godot_cef.ps1`.
- **Source:** `webui/` (Vite + React + TypeScript). It has a `.gdignore`, so Godot never scans it (`node_modules` would otherwise be imported).
- **Build output:** `ui/web/` (`npm run build` in `webui/`). Godot loads `res://ui/web/index.html` into one full-screen `CefTexture`. The build is committed so the game runs without Node.
- **Godot side:** `ui/hud/Hud.gd` (`class_name Hud`, `CanvasLayer`) owns the `CefTexture`, turns game state into JSON messages, and answers UI requests. It is created only on clients with a display (`DisplayServer.get_name() != "headless"` and `ClassDB.class_exists("CefTexture")`). The server and headless tests never create a browser.
- **Dev mode:** the client started with `-- --ui-dev` loads `GameConst.UI_DEV_URL` (`http://localhost:5173/`, the Vite dev server with hot reload) instead of the built page.

## Which tool for what
| Need | Tool |
|---|---|
| State Godot pushes (HUD numbers, role, timers, prompt, notifications) | Zustand store, replaced by each `hud` message |
| Screens/panels (HUD, later: body search, party, shop, inventory) | TanStack Router, memory history; Godot switches screens with `route` messages |
| Data the UI asks Godot for (request/response: search contents, shop catalog) | TanStack Query over `bridge.request(method, params)` |
| Long lists (search items, inventory, shop catalog, notification log) | TanStack Virtual |
| Styling | Tailwind v4 (`@tailwindcss/vite`) |

## IPC protocol
All messages are JSON strings. Godot sends with `CefTexture.send_ipc_message(JSON.stringify(msg))`; the page receives them in `window.onIpcMessage(text)`. The page sends with `window.sendIpcMessage(JSON.stringify(msg))`; Godot receives them on the `ipc_message(message: String)` signal.

Godot to page:
| `type` | Fields | Meaning |
|---|---|---|
| `hud` | `data: HudState` | Full HUD snapshot. Sent only when it changed. |
| `route` | `to: string` | Navigate to a route (`"/"` is the HUD). |
| `reply` | `id: number`, `ok: boolean`, `data?: unknown`, `error?: string` | Answer to a page `request`. |

`HudState`:
```json
{
  "role": "CRIMINAL", "life": "ALIVE",
  "cash": 50, "bag": 500, "notoriety": 500,
  "timer": {"label": "Masking", "seconds": 2},
  "prompt": "E lockpick | V smash",
  "notifications": ["Looted $300 (silent)"]
}
```
`timer` is `null` when no timer runs. `prompt` is `""` when nothing is in reach.

Page to Godot:
| `type` | Fields | Meaning |
|---|---|---|
| `ready` | none | Page loaded. Godot replies by sending the current `hud` snapshot and the current `route`. |
| `request` | `id: number`, `method: string`, `params: object` | Ask Godot for data. Godot always answers with one `reply` carrying the same `id`. Unknown method: `ok: false`, `error: "unknown_method"`. |

Methods so far: `ping` (replies `{"pong": true}`). Screen cards add their own.

## Input
The HUD is display-only: the `CefTexture` uses `mouse_filter = MOUSE_FILTER_IGNORE` and `focus_mode = FOCUS_NONE`, so mouse and keys reach the game. Interactive panels (later) switch to `MOUSE_FILTER_STOP` and free the mouse while open.

## Open items
- Export: Godot export must include `ui/web/*` as non-resource files (export filter), checked when export is set up.
- Remote DevTools is on by default (port 9229). Turn it off for release builds (`godot_cef/debug/remote_devtools_port`).
- Visual theme: neutral placeholder until the owner picks one.
