export type HudTimer = {
  label: string
  seconds: number
}

export type HudState = {
  role: string
  life: string
  cash: number
  bag: number
  notoriety: number
  timer: HudTimer | null
  prompt: string
  notifications: string[]
}

export type GodotToPage =
  | { type: 'hud'; data: HudState }
  | { type: 'route'; to: string }
  | { type: 'reply'; id: number; ok: boolean; data?: unknown; error?: string }

export type PageToGodot =
  | { type: 'ready' }
  | { type: 'request'; id: number; method: string; params: Record<string, unknown> }
