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
}

export type SearchItem = { uid: number; id: string; label: string; value: number; source: string }
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

export type GodotToPage =
  | { type: 'hud'; data: HudState }
  | { type: 'search'; data: SearchView | null }
  | { type: 'inventory'; data: InventoryView }
  | { type: 'route'; to: string }
  | { type: 'reply'; id: number; ok: boolean; data?: unknown; error?: string }

export type PageToGodot =
  | { type: 'ready' }
  | { type: 'request'; id: number; method: string; params: Record<string, unknown> }
