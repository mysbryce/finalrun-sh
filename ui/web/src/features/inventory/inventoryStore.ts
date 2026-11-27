import { create } from 'zustand'
import type { InventoryView } from '@/lib/ipc/protocol'

type InventoryStore = {
  inventory: InventoryView | null
  selectedUid: number | null
  setInventory: (view: InventoryView) => void
  select: (uid: number | null) => void
}

export const useInventoryStore = create<InventoryStore>((set) => ({
  inventory: null,
  selectedUid: null,
  setInventory: (view) =>
    set((state) => {
      const uid = state.selectedUid
      const present =
        uid !== null && (view.bag.some((i) => i.uid === uid) || view.gear.some((i) => i.uid === uid))
      return { inventory: view, selectedUid: present ? uid : null }
    }),
  select: (uid) => set({ selectedUid: uid }),
}))
