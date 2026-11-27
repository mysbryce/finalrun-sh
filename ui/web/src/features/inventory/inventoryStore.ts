import { create } from 'zustand'
import type { InventoryView } from '@/lib/ipc/protocol'
import { moveBagItem } from './placement'

type InventoryStore = {
  inventory: InventoryView | null
  selectedUid: number | null
  setInventory: (view: InventoryView) => void
  select: (uid: number | null) => void
  moveLocal: (uid: number, slot: number) => void
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
  moveLocal: (uid, slot) =>
    set((state) => {
      const inv = state.inventory
      if (!inv) return {}
      return { inventory: { ...inv, bag: moveBagItem(inv.bag, uid, slot, inv.bagSlots) } }
    }),
}))
