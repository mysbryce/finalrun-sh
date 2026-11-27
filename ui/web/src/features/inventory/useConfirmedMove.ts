import { useCallback, useEffect, useRef } from 'react'
import { request } from '@/lib/ipc/bridge'
import { useInventoryStore } from './inventoryStore'
import { MOVE_CONFIRM_MS } from './layout'

const CONFIRM_NOTICE = 'Move could not be confirmed.'

/** Optimistic bag move that reverts when no snapshot confirms it within MOVE_CONFIRM_MS. */
export function useConfirmedMove(): (uid: number, slot: number) => void {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const seq = useInventoryStore((s) => s.seq)

  const clear = useCallback(() => {
    if (timer.current !== null) clearTimeout(timer.current)
    timer.current = null
  }, [])

  // Any new snapshot settles the move.
  useEffect(() => clear, [seq, clear])

  return useCallback(
    (uid: number, slot: number) => {
      const store = useInventoryStore.getState()
      store.moveLocal(uid, slot)
      clear()
      timer.current = setTimeout(() => {
        timer.current = null
        useInventoryStore.getState().revert(CONFIRM_NOTICE)
      }, MOVE_CONFIRM_MS)
      request('inventory.move', { uid, slot }).catch((e: unknown) => {
        const code = e instanceof Error ? e.message : ''
        clear()
        useInventoryStore.getState().revert(code === 'timeout' ? CONFIRM_NOTICE : null)
      })
    },
    [clear],
  )
}
