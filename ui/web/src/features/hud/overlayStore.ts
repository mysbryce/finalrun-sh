import { create } from 'zustand'
import type { GameOverlayView, TransferView } from '@/lib/ipc/protocol'

type OverlayStore = {
  transfer: TransferView | null
  overlay: GameOverlayView | null
  setTransfer: (transfer: TransferView | null) => void
  setOverlay: (overlay: GameOverlayView | null) => void
}

// Host-owned lifetimes: the page shows what Godot sent until a null arrives.
export const useOverlayStore = create<OverlayStore>((set) => ({
  transfer: null,
  overlay: null,
  setTransfer: (transfer) => set({ transfer }),
  setOverlay: (overlay) => set({ overlay }),
}))
