export type HudTimer = { label: string; seconds: number }
export type InteractAction = { key: string; label: string }
export type HudInteract = { title: string; actions: InteractAction[] }
export type PartyMember = {
  name: string
  health: number
  maxHealth: number
  life: string
  leader: boolean
  away: boolean
}
export type HotbarSlot = { label: string; count?: number } | null
export type HudState = {
  role: string
  life: string
  health: number
  maxHealth: number
  cash: number
  bag: number
  notoriety: number
  heading: number
  timer: HudTimer | null
  interact: HudInteract | null
  notifications: string[]
  self: { name: string }
  party: PartyMember[]
  hotbar: HotbarSlot[]
  activeSlot: number
  net: { fps: number; ping: number }
  weaponsLocked?: boolean
  heistAlert?: HeistAlertView | null
  surrenderAvailable?: boolean
  channels?: DownedChannels | null
}

export type SearchItem = {
  uid: number
  id: string
  label: string
  value: number
  source: string
  w: number
  h: number
  slot: number
}
export type SearchView = { target: number; title: string; items: SearchItem[] }

export type InventoryItem = {
  uid: number
  id: string
  label: string
  value: number
  source: string
  slot: number
  w: number
  h: number
}
export type InventoryView = {
  cash: number
  bagValue: number
  bagSlots: number
  bag: InventoryItem[]
  gear: InventoryItem[]
}

export type BootPhase = 'title' | 'assets' | 'cef' | 'connecting' | 'ready' | 'failed'
export type BootError =
  | 'asset_load_failed'
  | 'cef_unavailable'
  | 'cef_timeout'
  | 'invalid_endpoint'
  | 'connection_failed'
  | 'connection_timeout'
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
  | 'invalid_endpoint'
  | 'invalid_server_id'
  | 'server_not_found'
  | 'server_full'
  | 'version_mismatch'
  | 'connection_failed'
  | 'connection_timeout'
  | 'disconnected'
  | 'discovery_unavailable'

export type PartyPeer = {
  peerId: number
  name: string
  leader: boolean
  isSelf: boolean
  presence: 'in_session' | 'unknown'
  canKick: boolean
}
export type ServerPlayer = {
  peerId: number
  name: string
  canInvite: boolean
}
export type PartyInvite = {
  inviterPeerId: number
  name: string
  expiresInSeconds: number
  canAccept: boolean
}
export type PartyView = {
  members: PartyPeer[]
  players: ServerPlayer[]
  incoming: PartyInvite | null
  canCreate: boolean
  canInvite: boolean
  canLeave: boolean
  pending: 'create' | 'invite' | 'accept' | 'decline' | 'leave' | 'kick' | null
  issue:
    | 'party_full'
    | 'invite_invalid'
    | 'invite_expired'
    | 'invites_blocked'
    | 'not_leader'
    | 'role_conflict'
    | 'not_available'
    | 'timeout'
    | null
}

export type PatchNote = {
  version: string
  publishedOn: string
  title: string
  summary: string
}
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
export type DeviceOption = {
  id: string
  label: string
  available: boolean
}
export type SettingAvailability = {
  visible: boolean
  enabled: boolean
  reason:
    | 'coming_later'
    | 'unsupported'
    | 'requires_voice'
    | 'requires_mode'
    | 'requires_backend'
    | 'debug_only'
    | null
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
export type GameOverlayView = ReceiptTiming &
  (
    | { kind: 'death'; cause: 'bleed_out' | 'finished' | 'other'; destination: 'Motel' }
    | {
        kind: 'arrest'
        cause: 'surrender' | 'cuffed'
        destination: 'Motel'
        bagForfeited: true
        gearKept: true
      }
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

export type GodotToPage =
  | { type: 'hud'; data: HudState }
  | { type: 'search'; data: SearchView | null }
  | { type: 'inventory'; data: InventoryView }
  | { type: 'route'; to: string }
  | { type: 'reply'; id: number; ok: boolean; data?: unknown; error?: string }
  | { type: 'boot'; data: BootView }
  | { type: 'lobby'; data: LobbyView }
  | { type: 'party'; data: PartyView | null }
  | { type: 'settings'; data: SettingsView }
  | { type: 'transfer'; data: TransferView | null }
  | { type: 'game_overlay'; data: GameOverlayView | null }

export type PageToGodot =
  | { type: 'ready' }
  | { type: 'request'; id: number; method: string; params: Record<string, unknown> }
