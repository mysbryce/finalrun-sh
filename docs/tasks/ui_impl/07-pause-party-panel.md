# ui_impl 07: party panel in the pause menu (roster, invite with expiry, accept/decline, leave, kick)

Design source: `docs/ui-design/04-hud.md` ("Pause menu" drawing, layout rows A10-A31, "Life and outcome surfaces" -> Pause), `docs/ui-design/DATA_CONTRACTS.md` (`PartyPeer`, `ServerPlayer`, `PartyInvite`, `PartyView`, `party.*` methods, the invitation paragraph). Card 06 added the pause route and `PauseScreen`. Read `features/party/PartyService.gd`, `autoload/ServerManager.gd` (party RPCs and facades), `features/player/PlayerService.gd`, `ui/hud/Hud.gd`, `main/Main.gd`, `ui/web/src/features/pause/PauseScreen.tsx` as they are now.

## Decisions for this card (supervisor)
- Invite expiry: `GameConst.PARTY_INVITE_TTL_MS: int = 30000`. The server stores the expiry and rejects late accepts; the client counts down locally from the TTL it receives and hides the invite at 0.
- Roster = every connected player known to the server except the requester, fetched when the pause menu opens (`server_request_party_roster` -> `client_party_roster(peers)`); names are `Hud.player_name(peer_id)` (`Player <id>`), so the picker label is `Player <id>`.
- `PartyView.issue` stays null and `canAccept` is "not already in a party" (the server still checks roles/life and replies with notifications). `# ponytail:` comments on both.
- `pending` is set when the page sends a party request and cleared on the next party/roster/invite update or after 5 s (`GameConst.PARTY_PENDING_TIMEOUT_MS: int = 5000`).
- The party snapshot is published continuously like the HUD (only when its JSON changed), so the invite countdown updates once per second.

## Rules
- Server-authoritative: the page and the client never decide party membership. Server RPC handlers validate the sender (`multiplayer.get_remote_sender_id()`), follow the existing `@rpc("any_peer", "call_remote", "reliable")` / `@rpc("authority", "call_remote", "reliable")` patterns in `ServerManager.gd`.
- Godot: `ui/` never references `ServerManager`; `Hud` emits signals, `Main` wires them. No magic numbers. Tests extend `TestCase` (existing party tests: `tests/features/party/test_party.gd`, `test_party_roles.gd`; read them first).
- Web: `app/ -> features/ -> lib/`; features never import each other; `import type`; no new packages; reuse `lib/ui` (`Button`, `Dropdown`, `Modal`).
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; vitest `pool: 'threads'` configured; do not start a Vite dev server; `ui/dist/assets` is not readable for you.

## Steps
### Server
1. `GameConst.gd`: `PARTY_INVITE_TTL_MS`, `PARTY_PENDING_TIMEOUT_MS` (values above) next to `PARTY_MAX_MEMBERS`.
2. `PartyService.gd`:
   - `invite_to_party(inviter_id, target_id, now_ms: int = Time.get_ticks_msec())` stores `"expires_ms": now_ms + PARTY_INVITE_TTL_MS` and sends `client_party_invite` with `[inviter_id, PARTY_INVITE_TTL_MS / 1000]`.
   - `accept_party_invite(target_id, inviter_id, now_ms: int = Time.get_ticks_msec())`: an expired invite is erased, the target is notified `Party invite expired`, returns false.
   - `func decline_party_invite(target_id: int, inviter_id: int) -> bool`: only when the pending invite matches the inviter: erase it, notify the inviter `Player <target> declined the invite`, return true.
   - Existing callers keep working (default args).
3. `PlayerService.gd`: `func peer_ids() -> Array[int]` (connected players, from `_states`), if no equivalent exists.
4. `ServerManager.gd`:
   - RPC `server_request_party_decline(inviter_peer_id: int)` -> `_parties.decline_party_invite(sender, inviter_peer_id)`.
   - RPC `server_request_party_roster()` -> `rpc_id(sender, "client_party_roster", peers)` with `_players.peer_ids()` minus the sender.
   - Client RPCs: `client_party_invite(inviter_id: int, ttl_seconds: int)` emits `party_invite_received(inviter_id, ttl_seconds)` (update the signal); `client_party_roster(peers: Array)` emits new signal `party_roster_received(peers: Array)`.
   - Facades `request_party_decline(inviter_peer_id)`, `request_party_roster()`.
5. Tests (extend `test_party.gd` or add `tests/features/party/test_party_invites.gd`): accept within TTL works; accept after TTL fails and erases the invite; decline erases the invite and returns true only for the matching inviter; a declined invite cannot be accepted.
### Client (Godot)
6. `Hud.gd`:
   - State: `_roster: Array[int]`, `_invite: Dictionary` (`inviter`, `expires_ms`, empty when none), `_party_pending: String` + `_party_pending_ms: int`, `_last_party_json`.
   - `static func party_view(self_id: int, members: Array, leader_id: int, roster: Array, invite: Dictionary, pending: String, now_ms: int) -> Dictionary` returning exactly the `PartyView` keys: `members` (each `PartyPeer`: `peerId`, `name` = `player_name`, `leader`, `isSelf`, `presence: "in_session"`, `canKick` = self is leader and not self; include self when in a party), `players` (roster minus self and members: `ServerPlayer` with `canInvite` = party not full), `incoming` (when `invite` set and not expired: `inviterPeerId`, `name`, `expiresInSeconds` = ceil of remaining seconds, `canAccept` = not in a party; else null), `canCreate` (not in a party), `canInvite` (party size < `PARTY_MAX_MEMBERS`), `canLeave` (in a party), `pending` (null when empty), `issue: null`.
   - `func set_roster(peers: Array)`, `func set_invite(inviter_id: int, ttl_seconds: int, now_ms: int)`, `func clear_party_session()` (members, leader, roster, invite, pending all cleared). Each update clears `_party_pending`.
   - In `_process` (when the page is ready and a local player id is known): expire the pending flag after `PARTY_PENDING_TIMEOUT_MS`, drop an expired invite, build `party_view`, `publish("party", view)` only when the JSON changed.
   - `route_request`: `party.create` `{}` -> `["party", "create", 0]`; `party.invite` `{targetPeerId}` / `party.kick` `{targetPeerId}` / `party.accept` `{inviterPeerId}` / `party.decline` `{inviterPeerId}` -> `["party", "<verb>", id]` with `bad_params` for a missing or non-positive id; `party.leave` `{}` -> `["party", "leave", 0]`. Signal `party_action_requested(verb: String, peer_id: int)`; `_on_ipc_message` sets `_party_pending = verb` and emits it. A `decline` also clears `_invite` locally right away.
7. `Main.gd`:
   - `party_action_requested` -> the matching `ServerManager.request_party_*` facade (`create`, `invite`, `accept`, `decline`, `leave`, `kick`).
   - When the pause menu opens (the Esc branch that calls `_hud.open_pause()`), call `ServerManager.request_party_roster()`.
   - `ServerManager.party_invite_received` -> `_hud.set_invite(inviter, ttl, Time.get_ticks_msec())` and `_hud.add_notification("Party invite from Player <id>: press Esc to answer", <client now ms as the existing notification calls use>)`; `party_roster_received` -> `_hud.set_roster(peers)`.
   - `_leave_session()` and `_show_lobby(...)` call `_hud.clear_party_session()`.
   - Remove the now-redundant debug `KEY_P` create-party key and its text in the controls print line (the pause panel replaces it).
8. Tests (`test_hud.gd`): `party_view` with no party (canCreate true, members empty, players from roster minus self); as leader with 2 members (canKick on the other member only, self included with `isSelf`); full party (`canInvite` false, players `canInvite` false); invite remaining 12.2 s -> `expiresInSeconds` 13; expired invite -> `incoming` null; `route_request` party methods incl. `bad_params`.
### Web
9. `features/pause/partyStore.ts` (zustand `{ party: PartyView | null; setParty }`); wire `setParty` in `main.tsx`; dev preview `#pause` also sets a demo party (`features/pause/demoParty.ts`: leader self + 1 member, 2 roster players, an incoming invite with 18 s).
10. `features/pause/PartyPanel.tsx`, rendered by `PauseScreen` only when `party` is not null, at the A10-A31 positions (absolute base px, `bg-zinc-900 rounded-md`):
    - Title `Party` (A11); feedback (A12): `Not in a party` / `<n> of 3 members` and, while `pending`, `Pending: <verb>` (`aria-live="polite"`).
    - Three member rows (A14-A22): identity `Player <id>` + `Leader` / `You` tags; `Kick` button (secondary compact) only when `canKick` -> `Modal` `Kick Player <id>?` (Cancel safe) -> `request('party.kick', { targetPeerId })`. Empty rows show `Empty slot` in zinc-500.
    - Picker (A23): `Dropdown` labelled `Invite player`, options `Player <id>` for `players` (disabled with reason `Party full` when `!canInvite`); empty list -> disabled with `No other players`.
    - Incoming invite (A24-A27) only when `incoming`: `Invite from Player <id> · <s> s`; `Accept` (primary, disabled when `!canAccept`) -> `party.accept { inviterPeerId }`; `Decline` (secondary) -> `party.decline { inviterPeerId }`.
    - Actions (A28-A31): left button `Create party` when `canCreate` (-> `party.create`), else `Invite` (-> `party.invite { targetPeerId: selected }`, disabled without a selection or when `!canInvite`); `Leave party` when `canLeave` -> `Modal` `Leave the party?` -> `party.leave`. Action feedback line for rejected requests (`Party request failed.`).
    - Buttons for the action named in `pending` show `loading`.
11. `features/pause/PartyPanel.test.tsx`: create when not in a party sends `party.create`; selecting a player and Invite sends `party.invite` with that peer id; Kick confirm sends `party.kick`; Accept / Decline send their methods with `inviterPeerId`; no panel when `party` is null; `Party full` disables options.
12. Checks: `npm run test`, `npm run build`; `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`; smoke `pwsh tools/smoke_local.ps1 -Clients 2`, wait 20 s, both clients connected and spawned, no `SCRIPT ERROR` in any log (server included), then `pwsh tools/smoke_local.ps1 -Stop` (never pipe the script's output). The click-through needs a human: say so.

## Do not
- No party staging in the lobby, no friends list, no party chat. No changes to party rules beyond expiry/decline/roster. Do not touch `docs/ui-design/`. Do not run git.

## Done when
- Web tests and build pass; Godot import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke clean.
- Final answer: files changed/created, web test summary line, build output list, last 3 Godot test lines, smoke result, what still needs a manual check.
