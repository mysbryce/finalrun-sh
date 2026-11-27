# 02 · Lobby

## 1. Purpose and entry/exit

Use `/lobby` to choose a server, inspect party membership, view appearance and news, and enter Settings. Godot opens it after boot, session leave, or connection recovery. Connecting can lead directly to `/transfer` with the current automatic Motel spawn. A connected staging variant keeps lobby visible until Enter Motel when the host and server support it.

## 2. ASCII wireframes

### Lobby

[Open SVG](wireframes/02-lobby.svg)

```text
+-----------------------------------------------------------------------------------------------+
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ||Lobby title              |               |Player identity     ||Connection state     ||   |
|   ++-------------------------+---------------+--------------------++---------------------++   |
|   ++Play title-------------++++Character title------------+++-+Party title---------------++   |
|   |+-----------------------+||+---------------------------+|| +--------------------------+|   |
|   |+Server ID field--------+||+---------------------------+|| +Party feedback------------+|   |
|   |+-----------------------+|||Character placeholder      ||| +--------------------------+|   |
|   |+Join by ID-+Quick Join-+|||                           ||| +Member 1 identity-+A25----+|   |
|   |+-----------------------+|||                           ||| +------------------+-------+|   |
|   ||Play feedback          ||||                           ||| |Member 2 identity |A28    ||   |
|   ||                       ||||                           ||| +------------------+-------+|   |
|   |+-----------------------+|||                           ||| |Member 3 identity |A31    ||   |
|   +-------------------------+||                           ||| +Invitation input----------+|   |
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
  [A32 Invitation input]
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

Right and bottom give offsets to the base-frame edges. Group bounds intentionally contain their children. Rows and regions use base CSS pixels.

### Lobby

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
| A32 | Invitation input | 848 | 376 | 64 | 308 | 368 | 36 | Party panel |
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

Join by ID and Quick Join share one row. Enter Motel replaces Quick Join when enabled. Member rows use a fixed identity area and a leader-only Kick slot. No extra footer buttons. Quit uses the 512 × 256 modal from [Settings](03-settings.md#settings-confirmation), with Cancel and Quit in the same action positions. The preview frame has inset line corners and a thin floor ring. Draw the placeholder locally while Godot's preview texture is unavailable.

## 4. States

| Region | Empty / loading | Ready / disabled / error |
|---|---|---|
| Identity and connection | “Player” when no name. “Offline”, “Finding server” or “Connecting” until ready. | Current display name and “Connected · 40 ms” style. Ping unavailable uses dash. Host error inline. Streamer mode displays alias and hides ID. |
| Play | Empty ID label and example placeholder. Normalize when submitted. Disable Join by ID until recognizable; Quick Join can be available independently. | While resolving or connecting, both actions lock and show a pending label. Failed attempts retain ID and show inline reason, then restore action. Unsupported discovery disables its action with reason. |
| Party | Offline: three open slots and explanation. Loading: keep rows stable. Solo: show self in slot one, Create Party enabled when permitted. | In party: leader label and icon. Pending disables duplicate sends. Invite requires capacity and server eligibility. Kick shown for other members only when allowed. Stale invite, full party and conflicting role show feedback. |
| Incoming invite | Hidden empty slot. | Show inviter plus Accept and Decline. Await party state on accept. Expired invite clears and announces once. |
| Character | Box with [icon] and “Character preview” while absent. Render placeholder status during data or model load. | Display body type and applied appearance summary only for a usable rig. On rendering failure keep frame and show unavailable. Preview controls wait for customization scope. |
| Patch notes | Loading preserves list region. Empty: “No patch notes yet.” | Latest first with version, date, title and short summary. On error show “Patch notes unavailable” and Retry. |
| Quit | Disabled while a quit request is in flight. | Confirmation uses Cancel as safe focus. Closing modal returns focus to Quit. |

## 5. Interactions

Focus starts on Play heading on route entry, then Server ID, Join by ID, Quick Join or Enter Motel, patch list or Retry, allowed party row actions, invitation input, Accept/Decline, Create/Invite, Leave, Settings, Quit. Preview placeholder is display-only. Enter in the server ID field submits Join by ID when valid. Normalize surrounding whitespace and uppercase, require exactly `^SV-SPACE-[0-9]{4}$`. Enter in target field submits allowed Invite. Use numeric peer ID from player label until account discovery exists. Escape dismisses a dialog; footer actions are reachable by Tab. Scroll patch notes with wheel, arrows or Page keys while focused. A leader can invite and kick under server rules. Leave is available to any party member when permitted. Confirm kick and leave in the same shared dialog geometry. Gamepad later.

## 6. Data

Read `lobby` → `LobbyView.playerName`, `connection`, `capabilities`, `canEnter`, `party`, `appearance`, `news`. Send `lobby.join`, `lobby.enter`, `lobby.news_retry`, `party.create`, `party.invite`, `party.accept`, `party.decline`, `party.leave`, `party.kick`, `settings.open`, `app.quit`. Route transitions arrive from Godot.

## 7. Godot side

[Main.gd](../../main/Main.gd) currently connects directly to local ENet. [ServerManager.gd](../../autoload/ServerManager.gd) assigns server ID and forwards party RPCs. [PlayerService.gd](../../features/player/PlayerService.gd) handles join and initial Motel transfer. [PartyService.gd](../../features/party/PartyService.gd) owns leader, capacity three and role compatibility and clears party on disconnect. [CharacterRig.gd](../../features/player/CharacterRig.gd) and [AppearanceData.gd](../../lib/data/AppearanceData.gd) supply the working-tree primitive rig and slots, with final base art planned. **NEW** Main-owned client lobby projection and optional server entry gate. **NEW** endpoint directory, bundled patch note reader and local preview viewport behind the CEF placeholder.

## 8. Accessibility

Use text ≥11 px and ordinary controls ≥14 px at ≥4.5:1. Pair leader marker with “Leader,” pending outline with “Pending,” and network dot with explicit connection text. Keep target labels unique by including action and member name or alias. Announce connection transitions without narrating ping updates. Use ellipsis for long names and retain opaque alias-safe accessible text.

## 9. Open questions

1. Approve a connected staging area before Motel or use direct join and keep party editing in Motel until staging is supported. Existing player join auto-spawns via transfer.
2. Choose server directory backing for ID and Quick Join. Until discovery ships, keep supported launch/local endpoint behavior and capability-gate both controls.
3. Confirm news content ownership and whether long patch notes need a separate future view.
4. Confirm party invite lookup beyond current peer IDs and whether friend/decline support ships before persistent accounts.
5. Approve final character preview asset load timing and whether appearance editing ships separately.
