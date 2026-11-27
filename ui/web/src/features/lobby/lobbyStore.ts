import { create } from 'zustand'
import type { LobbyView } from '@/lib/ipc/protocol'

type LobbyStore = {
  lobby: LobbyView | null
  setLobby: (view: LobbyView | null) => void
}

export const useLobbyStore = create<LobbyStore>((set) => ({
  lobby: null,
  setLobby: (view) => set({ lobby: view }),
}))
