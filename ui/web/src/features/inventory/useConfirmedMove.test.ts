import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_INVENTORY } from './demoInventory'
import { useInventoryStore } from './inventoryStore'
import { useConfirmedMove } from './useConfirmedMove'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => new Promise(() => {})) }))

const NOTICE = 'Move could not be confirmed.'
// Jewelry (uid 1) sits at slot 0; slot 6 is free.
const UID = 1
const slotOf = (uid: number) => useInventoryStore.getState().inventory!.bag.find((i) => i.uid === uid)?.slot

describe('useConfirmedMove', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    useInventoryStore.setState({ inventory: null, selectedUid: null, committed: null, notice: null, seq: 0 })
    useInventoryStore.getState().setInventory(structuredClone(DEMO_INVENTORY))
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => new Promise(() => {}))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('reverts with a notice when no snapshot arrives within 5000 ms', () => {
    const { result } = renderHook(() => useConfirmedMove())
    act(() => result.current(UID, 6))
    expect(slotOf(UID)).toBe(6)
    expect(request).toHaveBeenCalledWith('inventory.move', { uid: UID, slot: 6 })
    act(() => vi.advanceTimersByTime(4999))
    expect(useInventoryStore.getState().notice).toBeNull()
    act(() => vi.advanceTimersByTime(1))
    expect(useInventoryStore.getState().notice).toBe(NOTICE)
    expect(slotOf(UID)).toBe(0)
  })

  it('a snapshot before 5000 ms cancels the revert', () => {
    const { result } = renderHook(() => useConfirmedMove())
    act(() => result.current(UID, 6))
    act(() => vi.advanceTimersByTime(2000))
    const confirmed = structuredClone(DEMO_INVENTORY)
    confirmed.bag.find((i) => i.uid === UID)!.slot = 6
    act(() => useInventoryStore.getState().setInventory(confirmed))
    act(() => vi.advanceTimersByTime(5000))
    expect(useInventoryStore.getState().notice).toBeNull()
    expect(slotOf(UID)).toBe(6)
  })

  it('a bad_params rejection reverts at once without a notice', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('bad_params')))
    const { result } = renderHook(() => useConfirmedMove())
    act(() => result.current(UID, 6))
    await act(async () => {})
    expect(slotOf(UID)).toBe(0)
    expect(useInventoryStore.getState().notice).toBeNull()
  })

  it('a timeout rejection gives the confirm notice', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('timeout')))
    const { result } = renderHook(() => useConfirmedMove())
    act(() => result.current(UID, 6))
    await act(async () => {})
    expect(slotOf(UID)).toBe(0)
    expect(useInventoryStore.getState().notice).toBe(NOTICE)
  })
})
