import { create } from 'zustand'
import type { BootView } from '@/lib/ipc/protocol'

type SplashStore = {
  boot: BootView | null
  setBoot: (view: BootView | null) => void
}

export const useSplashStore = create<SplashStore>((set) => ({
  boot: null,
  setBoot: (view) => set({ boot: view }),
}))
