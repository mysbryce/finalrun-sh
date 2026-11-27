import { act, fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import type { SettingValue } from '@/lib/ipc/protocol'
import { CaptureDialog } from './CaptureDialog'
import { demoCapabilities } from './demoSettings'
import { SETTINGS, defaultsFor, entryFor } from './schema'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

let resolveCapture: (reply: { binding: string | null }) => void = () => undefined
let rejectCapture: (error: Error) => void = () => undefined

const defaults = defaultsFor(SETTINGS.map((e) => e.key))

function setup(key = 'bind_interact', values: Record<string, SettingValue> = defaults) {
  const onStage = vi.fn()
  const onClose = vi.fn()
  const utils = render(
    <CaptureDialog
      entry={entryFor(key)!}
      values={values}
      capabilities={demoCapabilities()}
      onStage={onStage}
      onClose={onClose}
    />,
  )
  return { onStage, onClose, ...utils }
}

const cancelCalls = () => vi.mocked(request).mock.calls.filter(([m]) => m === 'settings.capture_cancel').length

describe('CaptureDialog', () => {
  beforeEach(() => {
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation((method: string) => {
      if (method !== 'settings.capture') return Promise.resolve({})
      return new Promise((resolve, reject) => {
        resolveCapture = resolve as typeof resolveCapture
        rejectCapture = reject
      })
    })
  })

  it('sends settings.capture with the key and a 20 s timeout', () => {
    setup()
    expect(screen.getByRole('dialog', { name: 'Rebind Interact / lockpick / search' })).toBeInTheDocument()
    expect(request).toHaveBeenCalledWith('settings.capture', { key: 'bind_interact' }, 20000)
    expect(screen.getByText('15 s')).toBeInTheDocument()
  })

  it('a free key stages it and closes', async () => {
    const { onStage, onClose } = setup()
    await act(async () => resolveCapture({ binding: 'KeyN' }))
    expect(onStage).toHaveBeenCalledWith({ bind_interact: 'KeyN' })
    expect(onClose).toHaveBeenCalled()
  })

  it('a used key shows the conflict and Replace stages both keys', async () => {
    const { onStage, onClose } = setup()
    await act(async () => resolveCapture({ binding: 'KeyW' }))
    expect(screen.getByRole('dialog', { name: 'Key already in use' })).toBeInTheDocument()
    expect(screen.getByText('W is used by Move forward.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Replace' }))
    expect(onStage).toHaveBeenCalledWith({ bind_interact: 'KeyW', bind_move_forward: null })
    expect(onClose).toHaveBeenCalled()
  })

  it('Replace is disabled when the other key is fixed', async () => {
    setup('bind_interact', { ...defaults, bind_pause: 'KeyN' })
    await act(async () => resolveCapture({ binding: 'KeyN' }))
    expect(screen.getByText('N is used by Pause / back.')).toBeInTheDocument()
    expect(screen.getByText('That action cannot be unbound.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Replace' })).toBeDisabled()
  })

  it('a null reply closes without staging', async () => {
    const { onStage, onClose } = setup()
    await act(async () => resolveCapture({ binding: null }))
    expect(onStage).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalled()
  })

  it('Use left click shows the conflict with Fire', () => {
    setup()
    fireEvent.click(screen.getByRole('button', { name: 'Use left click' }))
    expect(screen.getByText('LMB is used by Fire.')).toBeInTheDocument()
    expect(cancelCalls()).toBe(1)
  })

  it('Clear on Fire asks first and Unbind stages null', () => {
    const { onStage, onClose } = setup('bind_fire')
    fireEvent.click(screen.getByRole('button', { name: 'Clear' }))
    expect(screen.getByRole('dialog', { name: 'Leave Fire unbound?' })).toBeInTheDocument()
    expect(onStage).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Unbind' }))
    expect(onStage).toHaveBeenCalledWith({ bind_fire: null })
    expect(onClose).toHaveBeenCalled()
  })

  it('Cancel sends settings.capture_cancel exactly once, also after unmount', async () => {
    const { onClose, unmount } = setup()
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    expect(onClose).toHaveBeenCalled()
    expect(cancelCalls()).toBe(1)
    unmount()
    expect(cancelCalls()).toBe(1)
  })

  it('a busy error shows the reason', async () => {
    setup()
    await act(async () => rejectCapture(new Error('busy')))
    expect(screen.getByText('Another rebind is in progress.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Close' })).toBeInTheDocument()
  })
})
