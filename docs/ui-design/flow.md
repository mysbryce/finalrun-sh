# Routes and input flow

Godot owns active route, cursor and game input. The page uses TanStack memory history in response to host messages. Focus behavior below is proposed for upgraded panels. Today CEF is set to `FOCUS_NONE` and interactive routes switch only the mouse filter and capture mode. Use explicit browser focus while a proposed interactive surface is active. Maintain a host action gate even when an event never reaches `_unhandled_input`; player movement polls physical keys each tick.

| Route / state | Entry trigger | Host messages | Cursor / filter | Keys active |
|---|---|---|---|---|
| Native boot | Godot startup or CEF failure | None until bridge `ready` | Visible / browser absent or IGNORE | Enter native retry, Esc native continue when offered |
| `/splash` | Godot detects CEF ready during boot | `route`, `boot` | Visible / STOP | Enter skips title or activates focused CTA. Tab on failure. |
| `/lobby` | Boot complete, leave or connection recovery | `route`, `lobby` | Visible / STOP | Tab, Shift+Tab, arrows in lists, Enter/Space. Escape closes dialog or input popover. |
| `/settings/graphics` | Host handles `settings.open` | `route`, `settings` | Visible / STOP | Tab, Shift+Tab, arrows, Enter/Space. Escape backs out of dialog, then screen. |
| `/settings/controls` | Host handles `settings.tab` | `route`, `settings` | Visible / STOP | Settings keys plus dedicated physical capture after activation. Escape cancels capture. |
| `/settings/social` | Host handles `settings.tab` | `route`, `settings` | Visible / STOP | Settings keys plus device menu keys. |
| `/settings/others` | Host handles `settings.tab` | `route`, `settings` | Visible / STOP | Settings keys plus credits and reset dialogs. |
| `/` alive | Observed local alive spawn, resumed play or panel closes | `route`, `hud` | Captured / IGNORE | Godot movement/action bindings, inventory and Escape pause. |
| `/` downed | Authoritative life changes to DOWNED | `hud`, `route` on panel eviction | Captured / IGNORE | Crawl, chat when shipped, and Escape pause. |
| `/` surrender prompt | Godot receives bound surrender key and eligibility | `game_overlay` | Visible / STOP | Tab cycles Cancel/Confirm, H or Enter confirms after release, Escape cancels. |
| `/inventory` | Host inventory key from live HUD only | `inventory`, `route` | Visible / STOP | Bound inventory key closes from Godot, Escape cancels drag then closes, Tab/Shift+Tab focuses when routed to browser as specified below. |
| `/search` | Server opens body search, host enters route | `search`, `inventory`, `route` | Visible / STOP | Bound close and Escape, Tab/Shift+Tab, Enter/Space, optional developer take-first shortcut. |
| `/pause` | Godot intercepts Escape in alive or downed HUD | `route`, latest `hud` | Visible / STOP | Escape resumes from root. Tab and Shift+Tab traverse. Enter or Space activates. |
| `/death` | Godot observes authoritative death snapshot or outcome | `game_overlay`, `route` | Visible / IGNORE | Display-only. No manual respawn. |
| `/arrest` | Godot observes successful surrender or cuff outcome | `game_overlay`, `route` | Visible / IGNORE | Display-only. No manual release. |
| `/transfer` | Host starts authorized map load | `transfer`, `route` | Visible / IGNORE during load. Visible / STOP on terminal error. | No actions during load. Tab and Enter for Return to Lobby on terminal error. |

## Transitions

| From → to | Who requests | Host transition and completion |
|---|---|---|
| Startup → splash | Godot | Native placeholder is visible immediately. `ready` advances only the CEF readiness condition. |
| Splash → splash | Page or host | `boot.skip` only advances title dwell. `boot.retry` retries failed stage. Host refreshes `boot`. |
| Splash → lobby | Godot or page | Host waits for boot gates. `boot.continue` handles terminal connection failure after required assets and CEF are ready. |
| Lobby → lobby | Page | `lobby.join` resolves ID or selects endpoint. Completing connection changes `lobby`; optional staging gates world enter. `lobby.news_retry` and party actions keep route stable. |
| Lobby → transfer | Page, then server | `lobby.enter`; Godot waits for authorized Motel load. With direct-join mode, Godot starts transfer after connect without a second click. |
| Lobby or pause → settings | Page | `settings.open` stores origin. Host navigates. |
| Settings → other tab | Page | `settings.tab` changes route. Draft survives. |
| Settings → lobby or pause | Page or Godot | `settings.close` returns to stored valid origin. If connection or life changes make origin invalid, Godot selects recovery route. |
| HUD → inventory | Godot | Inventory binding from alive HUD. Host supplies current snapshot before routing. |
| Inventory → HUD | Page or Godot | `inventory.close`, bound inventory key or Escape. If life/connection changes, host selects new state and cancels drag. |
| HUD or inventory → search | Server through Godot | Open body session takes precedence only while alive. Host sends search and inventory before switching route. |
| Search → HUD or outcome | Server, page or Godot | `search.close` requests server close on current target. Death, invalid target, disconnect and transfer evict immediately. Host sends null. |
| HUD → pause → HUD | Godot or page | Escape opens menu. `pause.resume` or Escape in menu root restores current eligible HUD and capture. |
| Pause → lobby | Page | Confirm and send `session.leave`. Godot disconnects and clears session-scoped party and search. |
| Lobby or pause → exit | Page | Confirm and send `app.quit`; Godot delivers reply if possible before shutdown. |
| HUD → downed → HUD | Server | Use authoritative life updates. Revive restores normal action map when spawn/context stays valid. |
| HUD → surrender → HUD | Godot, page | Revalidate availability. Cancel clears pending prompt before dispatch, or server rejects confirmation. |
| Surrender or downed → arrest | Server | Confirmed surrender or cuff queues bounded arrest receipt and begins Motel transfer. |
| Alive/downed → death | Server | Server applies death and schedules automatic Motel respawn. Host displays receipt without delaying loading. |
| HUD, death or arrest → transfer | Godot, authorized by server | Godot loads local map and acknowledges via existing transfer RPC flow. Page cannot send ack. |
| Transfer → HUD | Godot | Clear transfer after local spawn and matching authoritative state. |
| Transfer → lobby | Godot or page | Connection loss returns to lobby, stale route data cleared. If failed UI remains available, `transfer.return_to_lobby` cancels session locally and returns. |
| Any gameplay or gameplay-origin settings → lobby | Godot | ENet disconnect or unrecoverable session error. Clear modal, cursor, HUD session data and stale CEF focus. |

## Input routing precedence

1. A host disconnect, death, arrest or transfer invalidates stale gameplay interactions before page input can run. Pause never freezes the multiplayer session.
2. Active capture, display confirmation, other modal and open dropdown get keys in that order. Escape dismisses the innermost valid layer. Godot clears stale held movement and fire on entry to each interaction layer.
3. Default Tab remains the inventory shortcut with focus on the route root. Inside the inventory, Tab advances focus and Shift+Tab reverses it. Shift+Tab from root enters last focus target. Use Escape or Back to close from inside. A different inventory binding closes from anywhere in inventory. Search Tab always moves focus and never switches panels.
4. While a panel owns input, Godot suppresses movement/fire and every gameplay shortcut except explicitly routed panel controls or approved voice hotkeys. A leading escape press that opens a panel is consumed on that frame. Return to captured state only after all active panels close and a playable route is valid.
5. On CEF recreation let the native host keep the input gate until `ready` and replay. On action failure announce once and leave focus in place. When a focused item disappears, move to the next available item by reading order, then the footer close action.

Use the host as the source of device and keyboard capability. Gamepad later.
