# UI data contracts

Source baseline is [protocol.ts](../../ui/web/src/lib/ipc/protocol.ts), [Hud.gd](../../ui/hud/Hud.gd) and [WEB_UI.md](../design/WEB_UI.md). Decisions were approved 2026-11-27. **EXISTS** describes the inspected bridge. **CHANGED** extends a current snapshot or input path. **NEW** adds client presentation or a missing adapter. Gameplay remains server-authoritative.

## Envelope and replay

| Direction | Type | Status | Fields and delivery |
|---|---|---|---|
| Page → Godot | `ready` | EXISTS | No other keys. Install the page receiver first. Host replays active route and relevant snapshots. |
| Page → Godot | `request` | EXISTS | `id: number, method: string, params: Record<string, unknown>`. Positive page-local integer ID. |
| Godot → page | `reply` | EXISTS | `id: number, ok: boolean, data?: unknown, error?: string`. One reply per recognized request envelope. |
| Godot → page | `route` | CHANGED | Existing `to: string`, constrained to [flow.md](flow.md). Godot retains Settings origin. |
| Godot → page | `hud` | CHANGED | `data: HudState`. Full owner snapshot, with optional compatible extensions below. |
| Godot → page | `inventory` | EXISTS | `data: InventoryView`. Replay while owner inventory or body search is open. |
| Godot → page | `search` | EXISTS | `data: SearchView \| null`. Null invalidates the target and pending item UI. |
| Godot → page | `boot` | NEW | `data: BootView`. Build ID, startup gates and retry state. |
| Godot → page | `lobby` | NEW | `data: LobbyView`. Current connection, capability flags, view-only appearance and bundled news. |
| Godot → page | `party` | NEW | `data: PartyView \| null`. Current in-game party/roster and invitation state for Pause. Null clears it. |
| Godot → page | `settings` | NEW | `data: SettingsView`. Durable/session values, availability and display preview. |
| Godot → page | `transfer` | NEW | `data: TransferView \| null`. Clear after local spawn and matching state, or recovery. |
| Godot → page | `game_overlay` | NEW | `data: GameOverlayView \| null`. A bounded outcome receipt whose ID and remaining lifetime survive an early spawn. |

Messages remain JSON strings on the existing CefTexture bridge. A successful dispatch reply acknowledges local validation and forwarding. The authoritative snapshot or existing notification supplies the outcome. Host rejects stale connection/transfer generations, invalidates old panel state, and serializes route changes with its input gate. Replay never restarts a receipt or a heist-toast lifetime. Existing request timeout is 5 s, while capture uses the explicit longer timeout below.

Hud validates shape and emits signals, then Main forwards through ServerManager. Owner data, party projection and instance-scoped alerts retain their current audiences. Main handles boot and configured endpoint resolution. The page uses typed snapshots and local draft state.

## Existing and extended TS types

The block retains existing fields and adds compatible optional HUD fields. `SearchItem` footprint fields are already present in the working tree. Issued items and saved civilian gear remain excluded from body viewers by the server.

```ts
export type HudTimer = { label: string; seconds: number }
export type InteractAction = { key: string; label: string }
export type HudInteract = { title: string; actions: InteractAction[] }
export type PartyMember = {
  name: string; health: number; maxHealth: number; life: string
  leader: boolean; away: boolean
}
export type HotbarSlot = { label: string; count?: number } | null
export type HudState = {
  role: string; life: string; health: number; maxHealth: number
  cash: number; bag: number; notoriety: number; heading: number
  timer: HudTimer | null; interact: HudInteract | null; notifications: string[]
  self: { name: string }; party: PartyMember[]; hotbar: HotbarSlot[]
  activeSlot: number; net: { fps: number; ping: number }
  weaponsLocked?: boolean
  heistAlert?: HeistAlertView | null
  surrenderAvailable?: boolean
  channels?: DownedChannels | null
}
export type SearchItem = {
  uid: number; id: string; label: string; value: number
  source: string; w: number; h: number; slot: number
}
export type SearchView = { target: number; title: string; items: SearchItem[] }
export type InventoryItem = {
  uid: number; id: string; label: string; value: number
  source: string; slot: number; w: number; h: number
}
export type InventoryView = {
  cash: number; bagValue: number; bagSlots: number
  bag: InventoryItem[]; gear: InventoryItem[]
}
```

**CHANGED** `HudState` adds `weaponsLocked`, `heistAlert`, `surrenderAvailable` and `channels`. `weaponsLocked` is the single authoritative display flag for the approved “SAFE ZONE - weapons locked” copy in Motel, House and Center. Derive it from all server weapon-lock rules, including maps whose instance safezone flag differs. Omitted optional fields hide their UI when reading an old snapshot.

`role` uses CITIZEN, CRIMINAL, COP. `life` uses ALIVE, DOWNED, DEAD. Unknown strings get explicit fallback labels. `timer` covers the 3 s Masking channel or Bleeding out while DOWNED. Criminal role has no mask-expiry field. `party` excludes self, with at most two other members and health −1 when Away. `heading` is 0–359°, north at world −Z. Hotbar has six entries and `activeSlot` 0–5, selected by normal 1–6 bindings after debug migration.

**CHANGED** `surrenderAvailable` comes from the server's current eligibility check. H continues calling the existing Godot request directly. The existing `ServerManager.notification_received(text)` supplies success or rejection. Main passes text to `HudState.notifications`. The page reads neither eligibility nor outcome from button state. Decided 2026-11-27 (implementation): instead of matching notification copy, the server also sends the owner a typed `client_life_outcome(kind, cause)` RPC on death, successful surrender and cuff, before the Motel transfer starts. Main turns it into the `game_overlay` receipt, so server copy can change freely. The transfer RPC carries the `TransferView.reason`.

## New TS types

```ts
export type BootPhase = 'title' | 'assets' | 'cef' | 'connecting' | 'ready' | 'failed'
export type BootError =
  | 'asset_load_failed' | 'cef_unavailable' | 'cef_timeout'
  | 'invalid_endpoint' | 'connection_failed' | 'connection_timeout'
export type BootView = {
  phase: BootPhase
  buildId: string
  progress: { done: number; total: number } | null
  canSkipTitle: boolean
  error: BootError | null
  canRetry: boolean
}
export type ConnectionStatus = 'disconnected' | 'resolving' | 'connecting' | 'connected' | 'failed'
export type ConnectionError =
  | 'invalid_endpoint' | 'invalid_server_id' | 'server_not_found' | 'server_full'
  | 'version_mismatch' | 'connection_failed' | 'connection_timeout'
  | 'disconnected' | 'discovery_unavailable'
export type PartyPeer = {
  peerId: number; name: string; leader: boolean; isSelf: boolean
  presence: 'in_session' | 'unknown'; canKick: boolean
}
export type ServerPlayer = { peerId: number; name: string; canInvite: boolean }
export type PartyInvite = {
  inviterPeerId: number; name: string; expiresInSeconds: number; canAccept: boolean
}
export type PartyView = {
  members: PartyPeer[]
  players: ServerPlayer[]
  incoming: PartyInvite | null
  canCreate: boolean; canInvite: boolean; canLeave: boolean
  pending: 'create' | 'invite' | 'accept' | 'decline' | 'leave' | 'kick' | null
  issue:
    | 'party_full' | 'invite_invalid' | 'invite_expired' | 'invites_blocked'
    | 'not_leader' | 'role_conflict' | 'not_available' | 'timeout' | null
}
export type PatchNote = { version: string; publishedOn: string; title: string; summary: string }
export type PatchNotesFile = { entries: PatchNote[] }
export type LobbyView = {
  playerName: string | null
  connection: {
    status: ConnectionStatus
    serverId: string | null
    pingMs: number | null
    error: ConnectionError | null
  }
  capabilities: { joinById: boolean; quickJoin: boolean; partyStaging: boolean }
  canPlay: boolean
  party: PartyView | null
  appearance: {
    status: 'placeholder' | 'loading' | 'ready' | 'failed'
    bodyType: 'male' | 'female' | null
    slots: Record<string, string>
  }
  news: { status: 'loading' | 'ready' | 'failed'; entries: PatchNote[] }
}
export type SettingsTab = 'graphics' | 'controls' | 'social' | 'others'
export type SettingValue = boolean | number | string | string[] | number[] | null
export type SettingsValues = Partial<Record<string, SettingValue>>
export type DeviceOption = { id: string; label: string; available: boolean }
export type SettingAvailability = {
  visible: boolean
  enabled: boolean
  reason:
    | 'coming_later' | 'unsupported' | 'requires_voice'
    | 'requires_mode' | 'requires_backend' | 'debug_only' | null
}
export type SettingsView = {
  values: SettingsValues
  revision: number
  capabilities: Partial<Record<string, SettingAvailability>>
  devices: { input: DeviceOption[]; output: DeviceOption[] }
  displayModes: string[]
  pendingRestart: string[]
  preview: { token: string; secondsLeft: number } | null
  saveError: 'load_failed' | 'save_failed' | 'preview_reverted' | null
}
export type HeistAlertView = {
  id: string
  label: string
  location: string | null
  active: boolean
  toastSecondsLeft: number
}
export type DownedChannels = {
  revive: { secondsLeft: number; durationSeconds: number } | null
  finish: { secondsLeft: number; durationSeconds: number } | null
}
export type ReceiptTiming = { receiptId: string; remainingMs: number }
export type GameOverlayView = ReceiptTiming & (
  | { kind: 'death'; cause: 'bleed_out' | 'finished' | 'other'; destination: 'Motel' }
  | { kind: 'arrest'; cause: 'surrender' | 'cuffed'; destination: 'Motel'; bagForfeited: true; gearKept: true }
)
export type MapName = 'Motel' | 'LootyBay' | 'House' | 'Center'
export type TransferView = {
  mapName: MapName
  instanceId: string | null
  stage: 'loading' | 'waiting_for_spawn' | 'failed'
  reason: 'join' | 'travel' | 'extract' | 'death' | 'arrest'
  progress: number | null
  error: 'transfer_timeout' | 'map_load_failed' | 'disconnected' | null
}
```

Boot always connects to the configured endpoint, with development default 127.0.0.1:7777 and `--connect host:port` override in all builds. The host reads `buildId` from `ProjectSettings` `application/config/version`, falling back to `dev`. Both title labels use FinalRun. Failed boot offers Retry and Quit. Success runs the existing direct Motel transfer.

Current `LobbyView.capabilities` flags are all false. `canPlay` means configured-endpoint join is available. `party` stays null in the current lobby. Current in-game Pause receives `party` separately. `PatchNotesFile` is the static JSON shape at `ui/web/public/news.json`. The build copies it to `res://ui/dist/news.json`, which Main reads locally and projects into `LobbyView.news`. Long entries scroll in the news panel. Preview assets load after the lobby first becomes visible, following semi-realistic art direction.

Party invitations address currently connected peer IDs. The picker displays name and peer to disambiguate. Server supplies expiry and invalidates pending invites at expiration or disconnect. `expiresInSeconds` is remaining duration, with a local display countdown that never extends server expiry. `canAccept` includes current life and role checks. Decline remains available for a current invitation. Party max remains three including self, and existing role/life checks remain authoritative.

Settings keys and availability follow [settings-schema.json](settings-schema.json) and the single availability/storage rule in [03 Settings](03-settings.md#availability-and-storage). `SettingAvailability` is the host's computed projection for each key. `SettingsValues` carries both durable preferences and session entries. `party_invites` accepts `everyone` or `nobody` and `muted_players` holds positive integer peer IDs. Both reset per connection and are excluded from ConfigFile. Legacy saved values for these keys are ignored. `voice_input_threshold` is a −60–0 dBFS integer, step 1, default −40. Apply it to the local input level when Open Mic is active. Omitted keys use schema defaults. Reject unknown keys, malformed values, unsupported choices, out-of-range/step values and incompatible revisions.

Heist transport and audience stay with the existing same-instance Cop/Criminal path. Each alert gets an ID and up to 8 s of host-owned toast lifetime. `active` keeps its persistent line until server clear, independently of `toastSecondsLeft`. The host supplies active lifecycle state through that same scoped path. Replayed `toastSecondsLeft` stays within 0–8 and never renews the event.

Receipt lifetime is 900 ms from the host-observed authoritative outcome. `remainingMs` is 0–900 and replayed using the existing deadline. The same receipt survives a route change to the fresh HUD. Escape or click dismisses it without changing gameplay. Godot consumes a captured Escape/LMB dismissal before pause/fire. Page uses `overlay.dismiss` only when it owns the cursor.

Search packs items row-first into six columns, adding rows as needed beyond nine. Server bag slots remain 0–53. Search `slot: -1` is layout-only and its extra rows never extend the owner's bag. Requests always use UID.

## Request methods

All listed parameter objects are required. Empty requests use `{}`. Peer IDs and UIDs are positive integers. Success `{}` acknowledges local dispatch unless a row describes a local transaction. Common errors are host `unknown_method`, page bridge `timeout` and fallback `request_failed`. Method-specific errors follow.

| Method | Status | Params | Success `data` | Errors and effect |
|---|---|---|---|---|
| `ping` | EXISTS | `{}` | `{pong: true}` | Bridge check. |
| `search.take` | EXISTS | `{target: number, uid: number}` | `{}` | `no_search`, `bad_params`. Dispatch to current session; outcome in search and notification. |
| `search.close` | EXISTS | `{target: number}` | `{}` | `no_search`. Server close sends null and exits the panel. |
| `inventory.move` | EXISTS | `{uid: number, slot: number}` | `{}` | `bad_params`. Slot 0–53. Reconcile to authoritative inventory. |
| `inventory.close` | EXISTS | `{}` | `{}` | Local close while owner inventory is open. |
| `boot.skip` | NEW | `{}` | `{}` | `not_available`. Skip title dwell only after 250 ms. |
| `boot.retry` | NEW | `{}` | `{}` | `not_available`, `busy`. Restart failed stage and its timeout. |
| `lobby.join` | NEW | `{mode: 'configured' \| 'by_id' \| 'quick', serverId?: string}` | `{}` | `invalid_endpoint`, `invalid_server_id`, `discovery_unavailable`, `busy`. Current Play uses configured mode. Future modes require their capability. Direct successful join begins Motel transfer. |
| `lobby.news_retry` | NEW | `{}` | `{}` | `not_available`, `busy`. Main rereads bundled news and publishes lobby. |
| `party.create` | NEW | `{}` | `{}` | `not_available`, `busy`. Forward existing create request in game. |
| `party.invite` | NEW | `{targetPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Forward invite to selected current peer. |
| `party.accept` | NEW | `{inviterPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Server checks current invitation and expiration. |
| `party.decline` | NEW | `{inviterPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Server removes the current invite. |
| `party.leave` | NEW | `{}` | `{}` | `not_available`, `busy`. Forward leave. |
| `party.kick` | NEW | `{targetPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Forward leader-authorized kick. |
| `settings.open` | NEW | `{}` | `{}` | `not_available`. Remember lobby or Pause origin and enter Graphics. |
| `settings.tab` | NEW | `{tab: SettingsTab}` | `{}` | `bad_params`, `not_available`, `busy`. Host changes tab route. |
| `settings.close` | NEW | `{}` | `{}` | `not_available`, `busy`. Restore valid origin; revert any preview. |
| `settings.capture` | NEW | `{key: string}` | `{binding: string \| null}` | `bad_params`, `not_available`, `busy`. Physical input capture, cancel returns null. Host cancels after 15 s; page request timeout is 20 s. |
| `settings.capture_cancel` | NEW | `{}` | `{}` | Idempotent cancellation on route exit or focus loss. |
| `settings.apply` | NEW | `{revision: number, patch: SettingsValues}` | `{previewToken: string \| null}` | `bad_params`, `unsupported`, `binding_conflict`, `stale_revision`, `save_failed`, `busy`. Validate complete patch. Save durable values and update session values together after success. |
| `settings.display_confirm` | NEW | `{token: string, keep: boolean}` | `{}` | `bad_params`, `preview_expired`, `save_failed`. Keep commits staged patch. Revert restores prior display and durable/session values. |
| `pause.resume` | NEW | `{}` | `{}` | `not_available`. Restore current playable or downed HUD. |
| `session.leave` | NEW | `{}` | `{}` | `busy`, `not_available`. Graceful disconnect, clear session preferences and party projection, then show lobby with configured Play. |
| `app.quit` | NEW | `{}` | `{}` | `busy`, `not_available`. Reply before requesting Godot shutdown where possible. |
| `overlay.dismiss` | NEW | `{receiptId: string}` | `{}` | `bad_params`. Clear matching local receipt; already-expired ID is an idempotent no-op. |
| `transfer.return_to_lobby` | NEW | `{}` | `{}` | `not_available`, `busy`. Recover from a failed transfer by clearing the connection and showing configured Play. |

Party outcome state uses `PartyView.issue` and existing notifications. Snapshot replacement clears any matching pending action. Sender, role, life, party size, range and LOS continue to be server checks at execution and channel completion.

Settings uses one host revision and display preview transaction. Display timeout, focus loss or CEF failure reverts even when the page cannot respond. Validate before preview and commit ConfigFile with atomic replace. On success publish the new revision and capabilities. Physical bindings use stable key/mouse codes and optional Ctrl+, Alt+, Shift+ modifiers in that order. Normal hotbar 1–6, debug Ctrl+1–4/Y, B Reload and R Revive follow the approved mapping. Server-timed channel press/cancel behavior is specified in [04 HUD](04-hud.md#channel-activation). Streamer redaction runs in host-facing presentation before page text is emitted, retaining internal peer IDs for actions.
