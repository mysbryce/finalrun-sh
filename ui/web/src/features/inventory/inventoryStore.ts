import { create } from 'zustand'
import type { InventoryView } from '@/lib/ipc/protocol'
import { BAG_COLUMNS } from '@/lib/grid/gridLayout'
import { moveBagItem } from '@/lib/grid/placement'

type InventoryStore = {
  inventory: InventoryView | null
  /** Last snapshot from Godot; `revert` returns to it. */
  committed: InventoryView | null
  notice: string | null
  /** Bumped on every snapshot. */
  seq: number
  selectedUid: number | null
  setInventory: (view: InventoryView) => void
  select: (uid: number | null) => void
  moveLocal: (uid: number, slot: number) => void
  revert: (notice: string | null) => void
}

export const useInventoryStore = create<InventoryStore>((set) => ({
  inventory: null,
  committed: null,
  notice: null,
  seq: 0,
  selectedUid: null,
  setInventory: (view) =>
    set((state) => {
      const uid = state.selectedUid
      const present =
        uid !== null && (view.bag.some((i) => i.uid === uid) || view.gear.some((i) => i.uid === uid))
      return { inventory: view, committed: view, seq: state.seq + 1, notice: null, selectedUid: present ? uid : null }
    }),
  select: (uid) => set({ selectedUid: uid }),
  moveLocal: (uid, slot) =>
    set((state) => {
      const inv = state.inventory
      if (!inv) return {}
      return { inventory: { ...inv, bag: moveBagItem(inv.bag, uid, slot, inv.bagSlots, BAG_COLUMNS) } }
    }),
  revert: (notice) =>
    set((state) => (state.committed === null ? {} : { inventory: state.committed, notice })),
}))
