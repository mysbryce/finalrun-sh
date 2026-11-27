import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { HeistAlertView } from '@/lib/ipc/protocol'
import { useHeistToast } from './useHeistToast'

function alert(over: Partial<HeistAlertView> = {}): HeistAlertView {
  return { id: 'a1', label: 'Heist alert', location: 'Bank', active: true, toastSecondsLeft: 8, ...over }
}

describe('useHeistToast', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('counts the toast down from the snapshot value', () => {
    const { result } = renderHook(({ a }) => useHeistToast(a), { initialProps: { a: alert() } })
    expect(result.current).toBe('Heist alert · Bank')
    act(() => vi.advanceTimersByTime(7900))
    expect(result.current).toBe('Heist alert · Bank')
    act(() => vi.advanceTimersByTime(200))
    expect(result.current).toBeNull()
  })

  it('does not restart for a snapshot with the same id', () => {
    const { result, rerender } = renderHook(({ a }) => useHeistToast(a), {
      initialProps: { a: alert() },
    })
    act(() => vi.advanceTimersByTime(5000))
    rerender({ a: alert({ toastSecondsLeft: 8 }) })
    act(() => vi.advanceTimersByTime(3100))
    expect(result.current).toBeNull()
  })

  it('restarts for a new id', () => {
    const { result, rerender } = renderHook(({ a }) => useHeistToast(a), {
      initialProps: { a: alert() },
    })
    act(() => vi.advanceTimersByTime(5000))
    rerender({ a: alert({ id: 'a2', location: null }) })
    act(() => vi.advanceTimersByTime(7900))
    expect(result.current).toBe('Heist alert')
    act(() => vi.advanceTimersByTime(200))
    expect(result.current).toBeNull()
  })

  it('shows no toast when the snapshot has no toast time left', () => {
    const { result } = renderHook(() => useHeistToast(alert({ toastSecondsLeft: 0 })))
    expect(result.current).toBeNull()
  })
})
