# Routes and input flow

Godot owns active route, cursor and game input. The page responds to host route messages using TanStack memory history. Interactive surfaces require explicit browser focus and a host action gate, including movement that polls physical keys. Pause keeps the network session running.

## Routes

| Route / state | Entry trigger and snapshots | Cursor / filter | Keys active |
|---|---|---|---|
| Native boot | Godot startup or CEF failure. No bridge until `ready`. | Visible / browser absent or IGNORE | Eligible Enter title skip, native Retry/Quit and OS close. |
| `/splash` | Host receives CEF readiness and supplies `boot` plus `route`. | Visible / STOP | Enter skips title only after 250 ms. On failure Tab cycles Retry/Quit and Enter/Space activates. |
| `/lobby` | Established-session leave or later connection recovery, with `lobby`. | Visible / STOP | Tab, Shift+Tab, Enter/Space, news scrolling and dialog Escape. Default focus order includes one Play. |
| `/settings/graphics` | `settings.open` from Lobby/Pause supplies `settings` and route. | Visible / STOP | Tab, arrows, Enter/Space and Escape. |
| `/settings/controls` | `settings.tab` changes route; current settings draft persists. | Visible / STOP | Settings keys, then exclusive physical capture when activated. |
| `/settings/social` | `settings.tab` with capability-filtered rows. | Visible / STOP | Settings keys and enabled device/picker controls. |
| `/settings/others` | `settings.tab`, with English dropdown and available controls. | Visible / STOP | Settings keys, Credits and reset dialogs. |
| `/` alive | Local spawn and matching authoritative state, Resume or panel close. Read `hud`. | Captured / IGNORE | Movement, look, normal hotbar 1–6, world actions, direct H surrender, inventory and Escape Pause. |
| `/` downed | Authoritative DOWNED closes incompatible panels and updates `hud`. | Captured / IGNORE | Crawl, chat when available, Escape Pause. |
| `/` with receipt | Early spawn restores HUD while current `game_overlay` retains its existing deadline. | Captured / IGNORE | Escape or LMB dismisses receipt first and consumes that press. Other eligible movement remains active. |
| `/inventory` | Bound inventory key from alive HUD; `inventory` precedes route. | Visible / STOP | Bound inventory close, Escape cancel/close, routed Tab and Shift+Tab focus traversal. |
| `/search` | Server opens session; `search` and `inventory` precede route. | Visible / STOP | Q/bound close, Escape, Tab, Shift+Tab, Enter/Space and body-grid scrolling. |
| `/pause` | Escape from HUD. Read `hud` plus `party` for the adjoining management panel. | Visible / STOP | Escape Resume, Tab/Shift+Tab, member/picker/invite actions and confirmations. |
| `/death` | Authoritative death before a local new spawn, `game_overlay` plus route. | Visible / STOP while receipt is shown | Escape or click dismisses the current receipt. Host selects the valid waiting/transfer route. |
| `/arrest` | Host adapts the successful cuff/surrender notification before new spawn. | Visible / STOP while receipt is shown | Escape or click dismisses receipt without changing transfer. |
| `/transfer` | Authorized load, `transfer` plus route. Current receipt may remain above loading. | Visible / IGNORE normally. STOP during a receipt or terminal error. | Receipt dismissal only during load. On terminal error, Tab/Enter for Return to Lobby. |

## Transitions

| From → to | Trigger | Host behavior |
|---|---|---|
| Startup → splash | Godot | Read default endpoint and optional `--connect host:port` override. Start required assets, CEF and connection gates. Native fallback is immediate. |
| Splash → splash | Page/host | `boot.skip` only removes remaining title dwell after 250 ms. `boot.retry` retries the failed stage. Failure retains Retry/Quit. |
| Splash → transfer → HUD | Godot/server | Once required gates pass, continue the existing direct Motel entry and server transfer handshake. Boot never pauses in a connected staging lobby. |
| Lobby → transfer → HUD | Page/server | `lobby.join` with `mode: 'configured'` starts the same endpoint connection and direct Motel transfer. Play is locked while pending. |
| Lobby → lobby | Page | `lobby.news_retry` reloads bundled news. Future capability-enabled by-ID/Quick Join use `lobby.join`. Future staging can use party actions only after capability exists. |
| Lobby/Pause → Settings | Page | `settings.open` stores valid origin and enters Graphics. |
| Settings → other tab | Page | `settings.tab` changes route and retains draft. |
| Settings → origin | Page/host | `settings.close` after local dirty-state handling. Revert preview and restore valid origin; session failure selects recovery. |
| HUD → inventory → HUD | Godot/page | Inventory binding enters; `inventory.close`, bound close or Escape exits. Life, transfer or connection invalidates stale drag/panel state. |
| HUD/inventory → search | Server | Grant body session, send both snapshots and route. External search must land before this design ships. |
| Search → HUD/outcome | Server/page | `search.close` requests close. Target invalidation, life change or transfer evicts immediately and sends null. |
| HUD → Pause → HUD | Godot/page | Escape opens menu/party panel. `pause.resume` or root Escape resumes current eligible HUD. |
| Pause party state → updated party | Page/server | `party.create`, `party.invite`, `party.accept`, `party.decline`, `party.leave` or `party.kick` dispatch and await current server projection. Expiry clears incoming actions. |
| Pause → lobby | Page | Confirm, then `session.leave`. Disconnect and clear current-session permission/mute/party state. Lobby offers configured Play. |
| Lobby/Pause/failed boot → exit | Page/native | Confirm where applicable, send `app.quit` or native Quit. Godot replies where possible, then exits. |
| Alive → downed → alive | Server | Authoritative life and channel snapshots drive visibility. Revive restores the current eligible action map. |
| Alive Criminal → arrest/transfer | Godot/server | H directly calls the existing surrender request. Server snapshot provides hint eligibility; existing notification event provides success/rejection. Successful surrender or cuff creates receipt presentation. |
| Alive/downed → death/transfer | Server | Death and automatic Motel respawn continue while the 900 ms receipt lifetime runs. |
| Receipt + early spawn → HUD + same receipt | Godot | Switch to the new HUD, retain receipt ID/deadline, and render its remaining time above the HUD. Escape/LMB dismisses presentation first. |
| Receipt dismissal → valid current surface | Host/page | Captured input clears it in Godot. Visible-cursor click can send `overlay.dismiss` with current receipt ID. Select valid HUD, transfer or waiting surface without modifying game state. |
| HUD/outcome → transfer | Godot/server | Load authorized map and acknowledge via existing RPC flow. Page supplies no transfer acknowledgement. |
| Transfer → HUD | Godot | Observe local spawn plus matching authoritative state, clear transfer, carry any live receipt to HUD. |
| Transfer → lobby | Godot/page | Disconnect/failure clears session. `transfer.return_to_lobby` is available on terminal error. |
| Any session surface → lobby | Godot | Later unrecoverable disconnect closes stale settings/panel focus, clears connection state, and restores configured Play. |

## Input precedence

1. Authoritative connection, life and transfer changes invalidate incompatible interactions. Apply route, cursor, action gate and cleared held movement/fire together.
2. Capture, display preview, confirmation and dropdown receive keys from inner layer outward. Escape closes the current layer. Returning focus uses the originating control.
3. With a receipt above live HUD, consume Escape or LMB to dismiss it before Pause/fire. A visible-cursor receipt can use its page button. Use its current ID and existing deadline across replay. A newer outcome supersedes an older receipt.
4. Default Tab is the inventory shortcut from route root. Once focus enters inventory, Tab traverses and Shift+Tab reverses. Shift+Tab from root reaches the last focus target. Escape/Back closes from inside. A rebound inventory action closes from anywhere. Search Tab always traverses.
5. Panels suppress gameplay polling and shortcuts beyond their explicit controls and allowed voice keys. Body viewport scrolling and party-player selection retain focus without moving the character. The press that opens or closes a panel is consumed on that frame.
6. Server-timed channels begin on press. Movement, damage or the same action press cancels. Server validates completion. The downed document's hold-interact wording is recorded in [04 HUD](04-hud.md#channel-activation).
7. Browser recreation holds the native action gate through `ready` and replay. Focused-item removal selects the next row by reading order, then Close. Capability-hidden rows have no focus targets.

Two-client Windows CEF capture/focus and 90–110% UI scale are the single remaining verification item. Gamepad later.
