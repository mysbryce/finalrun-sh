import { create } from 'zustand'
import type { HudState } from '@/lib/ipc/protocol'

type HudStore = {
  hud: HudState | null
  setHud: (hud: HudState) => void
}

export const useHudStore = create<HudStore>((set) => ({
  hud: null,
  setHud: (hud) => set({ hud }),
}))
