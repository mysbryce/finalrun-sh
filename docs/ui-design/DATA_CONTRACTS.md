# UI data contracts

Working baseline from [protocol.ts](../../ui/web/src/lib/ipc/protocol.ts), [Hud.gd](../../ui/hud/Hud.gd) and [WEB_UI.md](../design/WEB_UI.md). The route and schemas below are proposed where marked. Numbers in milliseconds are monotonic or durations unless explicitly wall-clock. Positions and distances in gameplay contracts remain Godot units.

## Envelope and replay

| Direction | Type | Status | Fields and delivery |
|---|---|---|---|
| Page → Godot | `ready` | EXISTS | No other keys. Browser installs handler first. Host replays active route and latest relevant snapshots. |
| Page → Godot | `request` | EXISTS | `id: number, method: string, params: Record<string, unknown>`. ID is browser-local positive integer. |
| Godot → page | `reply` | EXISTS | `id: number, ok: boolean, data?: unknown, error?: string`. One reply per recognized request envelope. |
| Godot → page | `route` | CHANGED | Same `to: string` field. Allowed paths in [flow](flow.md); settings origin lives in Godot. |
| Godot → page | `hud` | CHANGED | `data: HudState`. Full snapshot. Optional extension fields remain safe to omit. |
| Godot → page | `inventory` | EXISTS | `data: InventoryView`. Resend for owner item and money changes on inventory or search route. |
| Godot → page | `search` | EXISTS | `data: SearchView \| null`. Null invalidates the open target and clears pending UI. |
| Godot → page | `boot` | NEW | `data: BootView`. Replaces current boot state. |
| Godot → page | `lobby` | NEW | `data: LobbyView`. Host composes data and gates actions. |
| Godot → page | `settings` | NEW | `data: SettingsView`. Host supplies durable values, availability and pending display preview. |
| Godot → page | `transfer` | NEW | `data: TransferView \| null`. Host clears when local spawn or recovery route is ready. |
| Godot → page | `game_overlay` | NEW | `data: GameOverlayView \| null`. Host supplies current life outcome or prompt. |

Serialize to JSON strings through existing bridge. A forwarded request acknowledges local validation and dispatch. A later authoritative snapshot or event supplies the result. Route transitions reject late responses or snapshots from an old ENet connection or transfer generation in the host. Browser discards route-owned pending UI on exit. The host replays the route plus latest active snapshots in a single order-preserving batch on `ready`. Restore cursor and action routing atomically in Godot. CEF has a 5 s request reply timeout already. A connection or instance transfer has its own lifecycle timeout.

Page sends to Hud only. Hud validates method and shape, then emits signals. Main forwards network-backed work via ServerManager. Owner-only status, instance-scoped alerts and party snapshots remain scoped to their current audiences. Screen-level messages never replicate bank, role, equipment, team or action outcomes to unauthorized peers.

## TS types

**EXISTS** signatures keep source keys. `SearchItem` footprint fields are already present in the inspected working tree. The server never exposes issued body gear or saved civilian gear to search viewers.

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
  safety?: 'safezone' | 'weapons_locked' | 'combat'
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

**CHANGED** `HudState` adds four optional fields above. `role` uses CITIZEN, CRIMINAL, COP or unknown fallback. `life` uses ALIVE, DOWNED, DEAD or unknown fallback. `heading` is 0–359° with north at world −Z. `timer` currently covers Masking while the 3 s channel is active, and Bleeding out while downed. The masked role has no expiry. `party` excludes self and contains at most two members. `away` carries health −1. Hotbar has six entries, active index 0–5. Unsupported net values display a dash when the host can distinguish them. `safety` distinguishes the instance flag from other maps that also lock weapons. When optional fields are omitted, hide their UI and retain existing timer, HUD and actions.

**NEW** source declarations and exact shapes

```ts
export type BootPhase = 'title' | 'assets' | 'cef' | 'connecting' | 'ready' | 'failed'
export type BootError = 'asset_load_failed' | 'cef_unavailable' | 'cef_timeout' | 'connection_failed' | 'connection_timeout'
export type BootView = {
  phase: BootPhase
  version: string
  buildId: string | null
  progress: { done: number; total: number } | null
  connectOnBoot: boolean
  canSkipTitle: boolean
  error: BootError | null
  canRetry: boolean
}
export type ConnectionStatus = 'offline' | 'resolving' | 'connecting' | 'connected' | 'failed'
export type ConnectionError = 'invalid_server_id' | 'server_not_found' | 'server_full' | 'version_mismatch' | 'connection_failed' | 'connection_timeout' | 'disconnected' | 'discovery_unavailable'
export type LobbyMember = {
  peerId: number; name: string; leader: boolean; isSelf: boolean
  presence: 'lobby' | 'in_session' | 'unknown'; canKick: boolean
}
export type LobbyInvite = { inviterPeerId: number; name: string }
export type LobbyParty = {
  members: LobbyMember[]; incoming: LobbyInvite | null
  canCreate: boolean; canInvite: boolean; canLeave: boolean
  pending: 'create' | 'invite' | 'accept' | 'leave' | 'kick' | null
  issue: 'party_full' | 'invite_invalid' | 'not_leader' | 'role_conflict' | 'not_available' | 'timeout' | null
}
export type PatchNote = { version: string; publishedOn: string; title: string; summary: string }
export type LobbyView = {
  playerName: string | null
  connection: { status: ConnectionStatus; serverId: string | null; pingMs: number | null; error: ConnectionError | null }
  capabilities: { joinById: boolean; quickJoin: boolean; partyStaging: boolean }
  canEnter: boolean
  party: LobbyParty | null
  appearance: { status: 'placeholder' | 'loading' | 'ready' | 'failed'; bodyType: 'male' | 'female' | null; slots: Record<string, string> }
  news: { status: 'loading' | 'ready' | 'failed'; entries: PatchNote[] }
}
export type SettingsTab = 'graphics' | 'controls' | 'social' | 'others'
export type SettingValue = boolean | number | string | string[] | null
export type SettingsValues = Partial<Record<string, SettingValue>>
export type DeviceOption = { id: string; label: string; available: boolean }
export type SettingAvailability = { enabled: boolean; reason: 'planned' | 'unsupported' | 'requires_voice' | 'requires_account' | 'requires_mode' | null }
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
export type HeistAlertView = { label: string; location: string | null; secondsLeft: number }
export type DownedChannels = {
  revive: { secondsLeft: number; durationSeconds: number } | null
  finish: { secondsLeft: number; durationSeconds: number } | null
}
export type GameOverlayView =
  | { kind: 'surrender'; status: 'confirm' | 'pending' | 'rejected'; error: 'no_cop_in_range' | 'not_available' | null }
  | { kind: 'death'; cause: 'bleed_out' | 'finished' | 'other'; destination: 'Motel' }
  | { kind: 'arrest'; cause: 'surrender' | 'cuffed'; destination: 'Motel'; bagForfeited: true; gearKept: true }
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

`SettingsValues` keys are the persisted entries of [settings-schema.json](settings-schema.json). Action entries have no runtime values. Optional keys read as schema defaults. Host validates unknown keys, type, bounds, step, enum values, binding conflicts, capability and revision. Strings representing resolution modes are candidates. `displayModes` narrows candidates to detected modes and `native`. Device IDs augment `system_default`; `null` only unbinds editable bindings. Key IDs are physical codes with optional `Ctrl+`, `Alt+` or `Shift+` chord modifiers in that order. Host serializes timers as remaining seconds using its synchronized clock conversion. No raw server monotonic timestamp crosses to JavaScript.

## Request methods

All parameter objects below are required unless empty. Fill no extra fields. Numbers for peer IDs and UIDs are positive integers. `{}` is a successful empty reply. All calls can fail with host `unknown_method` or local bridge `timeout`; bridge fallback is `request_failed` when no error is present. Listed error codes are method-specific.

| Method | Status | Params | Success `data` | Errors and effect |
|---|---|---|---|---|
| `ping` | EXISTS | `{}` | `{pong: true}` | Bridge check. No network round trip. |
| `search.take` | EXISTS | `{target: number, uid: number}` | `{}` | `no_search`, `bad_params`. Dispatch to current body session. Outcome in `search` and notification. |
| `search.close` | EXISTS | `{target: number}` | `{}` | `no_search`. Server close results in null snapshot and route change. |
| `inventory.move` | EXISTS | `{uid: number, slot: number}` | `{}` | `bad_params`. Slot 0–53. Dispatch, then reconcile to authoritative `inventory`. |
| `inventory.close` | EXISTS | `{}` | `{}` | Local route close if inventory is open. Search uses its own close. |
| `boot.skip` | NEW | `{}` | `{}` | `not_available`. Skip minimum title dwell only. |
| `boot.retry` | NEW | `{}` | `{}` | `not_available`, `busy`. Restart failed boot stage and reset timeout. |
| `boot.continue` | NEW | `{}` | `{}` | `not_available`. Continue offline to lobby from terminal connection failure. |
| `lobby.join` | NEW | `{mode: 'by_id' \| 'quick', serverId?: string}` | `{}` | `invalid_server_id`, `discovery_unavailable`, `busy`. Updates `lobby.connection`. |
| `lobby.enter` | NEW | `{}` | `{}` | `not_available`, `busy`. Requires host `canEnter`. Starts server-authorized Motel entry. |
| `lobby.news_retry` | NEW | `{}` | `{}` | `not_available`, `busy`. Reload bundled news snapshot. |
| `party.create` | NEW | `{}` | `{}` | `not_available`, `busy`. Forward existing create request. |
| `party.invite` | NEW | `{targetPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Forward invite. |
| `party.accept` | NEW | `{inviterPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Forward accept. |
| `party.decline` | NEW | `{inviterPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. NEW server invite removal. |
| `party.leave` | NEW | `{}` | `{}` | `not_available`, `busy`. Forward leave. |
| `party.kick` | NEW | `{targetPeerId: number}` | `{}` | `bad_params`, `not_available`, `busy`. Forward kick. |
| `settings.open` | NEW | `{}` | `{}` | `not_available`. Host records lobby or pause origin and routes to Graphics. |
| `settings.tab` | NEW | `{tab: SettingsTab}` | `{}` | `bad_params`, `not_available`, `busy`. Host sets tab route. |
| `settings.close` | NEW | `{}` | `{}` | `not_available`, `busy`. Host restores origin and makes any preview revert. |
| `settings.capture` | NEW | `{key: string}` | `{binding: string \| null}` | `bad_params`, `not_available`, `busy`. Capture physical input in Godot. Cancel returns null. Dedicated timeout 20 s in page, host exits capture after 15 s. |
| `settings.capture_cancel` | NEW | `{}` | `{}` | Idempotent host cancellation when route changes or page loses focus. |
| `settings.apply` | NEW | `{revision: number, patch: SettingsValues}` | `{previewToken: string \| null}` | `bad_params`, `unsupported`, `binding_conflict`, `stale_revision`, `save_failed`, `busy`. Reject whole patch on failure. |
| `settings.display_confirm` | NEW | `{token: string, keep: boolean}` | `{}` | `bad_params`, `preview_expired`, `save_failed`. Commit staged patch only on Keep, otherwise revert preview and keep durable values. |
| `pause.resume` | NEW | `{}` | `{}` | `not_available`. Restore valid live or downed route. |
| `session.leave` | NEW | `{}` | `{}` | `busy`, `not_available`. Disconnect gracefully then return offline to lobby. |
| `app.quit` | NEW | `{}` | `{}` | `busy`, `not_available`. Reply, then request Godot quit. |
| `surrender.cancel` | NEW | `{}` | `{}` | `not_available`. Close confirm before dispatch. |
| `surrender.confirm` | NEW | `{}` | `{}` | `not_available`, `busy`. Forward to existing server surrender request. |
| `transfer.return_to_lobby` | NEW | `{}` | `{}` | `not_available`, `busy`. Leave failed transfer safely, clear session, route to lobby. |

Party outcomes use server-owned state and `LobbyParty.issue`. Fresh party state supersedes pending state. Max three includes self. Search item `slot: -1` has no owner-grid position and is laid out in the search grid for that snapshot only. Inventory and search use UID for all item actions. Runtime server rejection UI continues using existing `notifications` where present. Never infer death, confiscation, transfer completion or item ownership from an IPC reply.

A proposed settings service keeps one preview transaction and one revision. Display timeout or focus loss reverts the window even if CEF is unavailable. Validate the full patch before entering preview. Commit ConfigFile only after preview approval with an atomic replace. Startup reads durable values only. `settings` then updates runtime capabilities and dirty-state reconciliation. Streamer redaction runs before text is emitted to the page and uses stable per-session aliases. Retain IDs internally for routing and action requests.
