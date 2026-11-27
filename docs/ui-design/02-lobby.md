# 02 · Lobby

## 1. Purpose and entry/exit

Use `/lobby` after leaving an established session or recovering from a later disconnect. Play joins the configured endpoint and continues directly through the existing Motel transfer. Boot performs its automatic connection through `/splash`. The current lobby shows Play, bundled news, an asset-agnostic character preview, Settings and Quit. The second drawing records future capability-enabled ID/Quick Join and party regions. Parties are created and managed in game through Pause as described in [04 HUD](04-hud.md).

## 2. ASCII wireframes

### Lobby with current capabilities

[Open SVG](wireframes/02-lobby.svg)

```text
+-----------------------------------------------------------------------------------------------+
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ||Lobby title              |               |Player identity     ||Connection state     ||   |
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ++Play title-------------++++Character title-------------------------------------------++   |
|   |+-----------------------+||+----------------------------------------------------------+|   |
|   |+Play-------------------+||+----------------------------------------------------------+|   |
|   |+-----------------------+|||Character placeholder                                     ||   |
|   |+-----------------------+|||                                                          ||   |
|   ||Play feedback          ||||                                                          ||   |
|   ||                       ||||                                                          ||   |
|   ||                       ||||                                                          ||   |
|   |+-----------------------+|||                                                          ||   |
|   +-------------------------+||                                                          ||   |
|   ++Patch notes title------++||                                                          ||   |
|   |+-----------------------+|||                                                          ||   |
|   |+-----------------------+|||                                                          ||   |
|   ||Patch notes list       ||||                                                          ||   |
|   ||                       ||||                                                          ||   |
|   ||                       |||+----------------------------------------------------------+|   |
|   ||                       ||||Appearance summary                                        ||   |
|   |+News action------------+|||                                                          ||   |
|   ++-----------------------++++----------------------------------------------------------++   |
|   +------------------------------------------------------------------+A18-----+-+Quit----++   |
|   +------------------------------------------------------------------+--------+-+--------++   |
+-----------------------------------------------------------------------------------------------+

[A01 Lobby header]
  [A02 Lobby title]
  [A03 Player identity]
  [A04 Connection state]
[A05 Play panel]
  [A06 Play title]
  [A07 Play]
  [A08 Play feedback]
[A09 News panel]
  [A10 Patch notes title]
  [A11 Patch notes list]
  [A12 News action]
[A13 Character preview]
  [A14 Character title]
  [A15 Character placeholder]
  [A16 Appearance summary]
[A17 Lobby footer]
  [A18 Settings]
  [A19 Quit]
```

### Lobby with future capabilities enabled

[Open SVG](wireframes/02-lobby-capabilities.svg)

```text
+-----------------------------------------------------------------------------------------------+
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ||Lobby title              |               |Player identity     ||Connection state     ||   |
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ++Play title-------------++++Character title------------+++-+Party title---------------++   |
|   |+-----------------------+||+---------------------------+|| +--------------------------+|   |
|   |+Server ID field--------+||+---------------------------+|| +Party feedback------------+|   |
|   |+-----------------------+|||Character placeholder      ||| +--------------------------+|   |
|   |+A08-------++Quick Join-+|||                           ||| +Member 1 identity-+A25----+|   |
|   |+-----------------------+|||                           ||| +------------------+-------+|   |
|   ||Play feedback          ||||                           ||| |Member 2 identity |A28    ||   |
|   ||                       ||||                           ||| +Member 3 identity-+A31----+|   |
|   |+-----------------------+|||                           ||| +------------------+-------+|   |
|   +-------------------------+||                           ||| +Server player picker------+|   |
|   ++Patch notes title------++||                           ||| +--------------------------+|   |
|   |+-----------------------+|||                           ||| +Invite sender-------------+|   |
|   |+-----------------------+|||                           ||| +A35-----+A36-----+--------+|   |
|   ||Patch notes list       ||||                           ||| +--------+--------+        ||   |
|   ||                       ||||                           ||| +A38---------+Leave party--+|   |
|   ||                       |||+---------------------------+|| +------------+-------------+|   |
|   ||                       ||||Appearance summary         ||| +Party action feedback-----+|   |
|   |+News action------------+|||                           ||| +--------------------------+|   |
|   ++-----------------------++++---------------------------+++-----------------------------+   |
|   +------------------------------------------------------------------+A42-----+-+Quit----++   |
|   +------------------------------------------------------------------+--------+-+--------++   |
+-----------------------------------------------------------------------------------------------+

[A01 Lobby header]
  [A02 Lobby title]
  [A03 Player identity]
  [A04 Connection state]
[A05 Play panel]
  [A06 Play title]
  [A07 Server ID field]
  [A08 Join by ID]
  [A09 Quick Join]
  [A10 Play feedback]
[A11 News panel]
  [A12 Patch notes title]
  [A13 Patch notes list]
  [A14 News action]
[A15 Character preview]
  [A16 Character title]
  [A17 Character placeholder]
  [A18 Appearance summary]
[A19 Party panel]
  [A20 Party title]
  [A21 Party feedback]
  [A22 Party slots]
    [A23 Member 1]
      [A24 Member 1 identity]
      [A25 Member 1 kick]
    [A26 Member 2]
      [A27 Member 2 identity]
      [A28 Member 2 kick]
    [A29 Member 3]
      [A30 Member 3 identity]
      [A31 Member 3 kick]
  [A32 Server player picker]
  [A33 Incoming invite]
    [A34 Invite sender]
    [A35 Accept invite]
    [A36 Decline invite]
  [A37 Party actions]
    [A38 Create or invite]
    [A39 Leave party]
    [A40 Party action feedback]
[A41 Lobby footer]
  [A42 Settings]
  [A43 Quit]
```

## 3. Layout

Right and bottom are insets from the 1280 × 720 frame. Parent bounds contain their children. Each drawing is a separate state.

### Lobby with current capabilities

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Lobby header | 48 | 32 | 48 | 632 | 1184 | 56 | Frame |
| A02 | Lobby title | 64 | 40 | 864 | 640 | 352 | 40 | Lobby header |
| A03 | Player identity | 624 | 40 | 376 | 640 | 280 | 40 | Lobby header |
| A04 | Connection state | 920 | 40 | 64 | 640 | 296 | 40 | Lobby header |
| A05 | Play panel | 48 | 112 | 880 | 344 | 352 | 264 | Frame |
| A06 | Play title | 64 | 128 | 896 | 564 | 320 | 28 | Play panel |
| A07 | Play | 64 | 164 | 896 | 516 | 320 | 40 | Play panel |
| A08 | Play feedback | 64 | 216 | 896 | 364 | 320 | 140 | Play panel |
| A09 | News panel | 48 | 392 | 880 | 80 | 352 | 248 | Frame |
| A10 | Patch notes title | 64 | 408 | 896 | 284 | 320 | 28 | News panel |
| A11 | Patch notes list | 64 | 448 | 896 | 128 | 320 | 144 | News panel |
| A12 | News action | 64 | 600 | 896 | 92 | 320 | 28 | News panel |
| A13 | Character preview | 416 | 112 | 48 | 80 | 816 | 528 | Frame |
| A14 | Character title | 432 | 128 | 64 | 564 | 784 | 28 | Character preview |
| A15 | Character placeholder | 432 | 168 | 64 | 184 | 784 | 368 | Character preview |
| A16 | Appearance summary | 432 | 552 | 64 | 96 | 784 | 72 | Character preview |
| A17 | Lobby footer | 48 | 652 | 48 | 24 | 1184 | 44 | Frame |
| A18 | Settings | 944 | 654 | 208 | 26 | 128 | 40 | Lobby footer |
| A19 | Quit | 1088 | 654 | 64 | 26 | 128 | 40 | Lobby footer |

### Lobby with future capabilities enabled

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Lobby header | 48 | 32 | 48 | 632 | 1184 | 56 | Frame |
| A02 | Lobby title | 64 | 40 | 864 | 640 | 352 | 40 | Lobby header |
| A03 | Player identity | 624 | 40 | 376 | 640 | 280 | 40 | Lobby header |
| A04 | Connection state | 920 | 40 | 64 | 640 | 296 | 40 | Lobby header |
| A05 | Play panel | 48 | 112 | 880 | 344 | 352 | 264 | Frame |
| A06 | Play title | 64 | 128 | 896 | 564 | 320 | 28 | Play panel |
| A07 | Server ID field | 64 | 164 | 896 | 516 | 320 | 40 | Play panel |
| A08 | Join by ID | 64 | 216 | 1060 | 464 | 156 | 40 | Play panel |
| A09 | Quick Join | 228 | 216 | 896 | 464 | 156 | 40 | Play panel |
| A10 | Play feedback | 64 | 268 | 896 | 364 | 320 | 88 | Play panel |
| A11 | News panel | 48 | 392 | 880 | 80 | 352 | 248 | Frame |
| A12 | Patch notes title | 64 | 408 | 896 | 284 | 320 | 28 | News panel |
| A13 | Patch notes list | 64 | 448 | 896 | 128 | 320 | 144 | News panel |
| A14 | News action | 64 | 600 | 896 | 92 | 320 | 28 | News panel |
| A15 | Character preview | 416 | 112 | 464 | 80 | 400 | 528 | Frame |
| A16 | Character title | 432 | 128 | 480 | 564 | 368 | 28 | Character preview |
| A17 | Character placeholder | 432 | 168 | 480 | 184 | 368 | 368 | Character preview |
| A18 | Appearance summary | 432 | 552 | 480 | 96 | 368 | 72 | Character preview |
| A19 | Party panel | 832 | 112 | 48 | 80 | 400 | 528 | Frame |
| A20 | Party title | 848 | 128 | 64 | 564 | 368 | 28 | Party panel |
| A21 | Party feedback | 848 | 164 | 64 | 516 | 368 | 40 | Party panel |
| A22 | Party slots | 848 | 216 | 64 | 356 | 368 | 148 | Party panel |
| A23 | Member 1 | 848 | 216 | 64 | 460 | 368 | 44 | Party slots |
| A24 | Member 1 identity | 856 | 220 | 178 | 464 | 246 | 36 | Member 1 |
| A25 | Member 1 kick | 1110 | 220 | 72 | 464 | 98 | 36 | Member 1 |
| A26 | Member 2 | 848 | 268 | 64 | 408 | 368 | 44 | Party slots |
| A27 | Member 2 identity | 856 | 272 | 178 | 412 | 246 | 36 | Member 2 |
| A28 | Member 2 kick | 1110 | 272 | 72 | 412 | 98 | 36 | Member 2 |
| A29 | Member 3 | 848 | 320 | 64 | 356 | 368 | 44 | Party slots |
| A30 | Member 3 identity | 856 | 324 | 178 | 360 | 246 | 36 | Member 3 |
| A31 | Member 3 kick | 1110 | 324 | 72 | 360 | 98 | 36 | Member 3 |
| A32 | Server player picker | 848 | 376 | 64 | 308 | 368 | 36 | Party panel |
| A33 | Incoming invite | 848 | 424 | 64 | 216 | 368 | 80 | Party panel |
| A34 | Invite sender | 856 | 430 | 72 | 266 | 352 | 24 | Incoming invite |
| A35 | Accept invite | 856 | 460 | 312 | 224 | 112 | 36 | Incoming invite |
| A36 | Decline invite | 976 | 460 | 192 | 224 | 112 | 36 | Incoming invite |
| A37 | Party actions | 848 | 520 | 64 | 104 | 368 | 96 | Party panel |
| A38 | Create or invite | 848 | 520 | 256 | 160 | 176 | 40 | Party actions |
| A39 | Leave party | 1032 | 520 | 64 | 160 | 184 | 40 | Party actions |
| A40 | Party action feedback | 848 | 568 | 64 | 104 | 368 | 48 | Party actions |
| A41 | Lobby footer | 48 | 652 | 48 | 24 | 1184 | 44 | Frame |
| A42 | Settings | 944 | 654 | 208 | 26 | 128 | 40 | Lobby footer |
| A43 | Quit | 1088 | 654 | 64 | 26 | 128 | 40 | Lobby footer |

The current view is the shipped state with all three lobby capabilities false. The future drawing defines reserved slots and stays hidden unless its relevant flags are true. With `partyStaging` false, preview expands into the right column. If party staging is enabled later, preview uses the narrower center column. If only discovery flags change, retain the expanded preview and reveal only the supported Play-panel controls. Empty gated slots collapse without focus targets. In the future party view, the Server player picker shows the current roster as `display name · peer ID`. Reuse the shared confirmation geometry for Quit and party destructive actions.

## 4. States

| Region | Empty / loading | Ready / disabled / error |
|---|---|---|
| Identity and connection | Use “Player” when the display name is absent. Show “Disconnected,” “Connecting” or “Reconnecting” from host status. | Name, connection label and known ping. Streamer mode uses aliases and redacts ID/endpoint. After connection, route directly into Motel. |
| Play | One enabled “Play” button when the configured endpoint can be joined. | Lock during connection and show pending feedback. Failure retains the button, a readable reason and retry capability. Success begins the existing transfer automatically. |
| Server discovery controls | `joinById` and `quickJoin` are false in the current build, so their controls are hidden. | When their respective capability is true in the future, use the ID field/Join by ID or Quick Join slots in the second drawing. Phase 7 owns directory support. |
| Party panel | `partyStaging` is false and the whole lobby party panel is hidden. | The second drawing is reserved for future staging. Current invites, membership and expiry are managed in game. |
| Character | Begin loading after the lobby is visible. Show [icon] placeholder silhouette while assets load. | The view-only preview uses supplied appearance after ready. Failure keeps the silhouette and a readable unavailable status. Layout accepts the current semi-realistic art direction. |
| Patch notes | Load the web-bundled `ui/web/public/news.json`. Preserve the list region while loading. Empty data shows “No patch notes yet.” | Entries scroll within this panel, newest first by version/date. Load failure offers Retry. Long summaries stay in this same scroll region. |
| Quit | Lock the button while the host quit request is pending. | Confirmation uses Cancel as safe focus, then Quit. Restore focus to the footer button on dismissal. |

In-game party invitations target currently connected players by display name and peer ID. Accept and Decline ship with server-controlled expiration. Render the invite's remaining seconds from `PartyView.incoming` and remove expired invitations when the host invalidates them. Current builds expose session-based invite preferences and no Friends option.

## 5. Interactions

Focus starts on the Play heading, then Play, patch notes or Retry, Settings and Quit. Preview stays view-only. Scroll the news list with wheel, arrows or Page keys while focused. Escape dismisses the innermost dialog. Gamepad later.

Future capability-enabled controls enter focus order only while visible. Server ID input normalizes surrounding whitespace and uppercase, then checks `^SV-SPACE-[0-9]{4}$`. Join by ID and Quick Join use their own capability. The future party panel uses the same server-player picker and member actions as in-game Pause. Selecting a player retains their peer ID, even when display names match. Incoming invite actions reference the inviter peer. Confirm Kick or Leave in the shared dialog geometry.

## 6. Data

Read `lobby` → `LobbyView.playerName`, `connection`, `capabilities`, `canPlay`, `party`, `appearance` and `news`. Play sends `lobby.join` with `mode: 'configured'`. Send `lobby.news_retry`, `settings.open` and `app.quit`. Future ID/Quick Join controls reuse `lobby.join` with their supported mode. Future staging uses `party.create`, `party.invite`, `party.accept`, `party.decline`, `party.leave` and `party.kick`. Current in-game party UI uses the `party` snapshot. Godot supplies route transitions.

## 7. Godot side

[Main.gd](../../main/Main.gd) owns configured endpoint and connection. [PlayerService.gd](../../features/player/PlayerService.gd) owns initial Motel transfer. [ServerManager.gd](../../autoload/ServerManager.gd) supplies server ID and party RPC forwarding. [PartyService.gd](../../features/party/PartyService.gd) owns membership, leader and max three. **CHANGED** PartyService gains explicit decline/expiry and supplies the current-player roster. [CharacterRig.gd](../../features/player/CharacterRig.gd) and [AppearanceData.gd](../../lib/data/AppearanceData.gd) supply view-only appearance. [ART_DIRECTION.md](../design/ART_DIRECTION.md) now specifies semi-realistic art. **NEW** Main-owned lobby projection and lazy preview viewport load after the lobby appears. **NEW** `ui/web/public/news.json` is static repo-owned input bundled with the web build. Main reads the copied `res://ui/dist/news.json` using FileAccess and JSON, then supplies the typed news state. `lobby.news_retry` reloads this bundled file and republishes the lobby snapshot. Network state and news state update independently.

## 8. Accessibility

Use text ≥11 px and ordinary controls ≥14 px at ≥4.5:1. Pair leader marker with “Leader,” pending outline with “Pending,” and network dot with explicit connection text. Keep target labels unique by including action and member name or alias. Announce connection transitions without narrating ping updates. Use ellipsis for long names and retain opaque alias-safe accessible text.

## 9. Decisions

1. Decided 2026-11-27: Play directly joins Motel. Hide the lobby party panel behind `partyStaging` until a staging area exists, and form parties in game.
2. Decided 2026-11-27: Hide Server ID and Quick Join behind their false current capabilities. Play uses the configured endpoint. Directory support belongs to Phase 7.
3. Decided 2026-11-27: Load repo-owned `ui/web/public/news.json` with the web build. Scroll all patch-note content inside the existing news panel.
4. Decided 2026-11-27: Target currently connected players by display name/peer ID. Ship Accept, Decline and expiring invitations. Friends support starts with persistent accounts in Phase 7.
5. Decided 2026-11-27: Lazy-load a view-only, asset-agnostic character preview after the lobby appears, using a placeholder silhouette until ready. Follow semi-realistic art direction and defer appearance editing to Phase 6.
