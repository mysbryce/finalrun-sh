import { create } from 'zustand'
import type { PartyView } from '@/lib/ipc/protocol'

type PartyStore = {
  party: PartyView | null
  setParty: (view: PartyView | null) => void
}

export const usePartyStore = create<PartyStore>((set) => ({
  party: null,
  setParty: (view) => set({ party: view }),
}))
