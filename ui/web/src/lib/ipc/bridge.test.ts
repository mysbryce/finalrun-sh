import { beforeEach, describe, expect, it, vi } from 'vitest'
import { handleMessage, installBridge, request, type BridgeDeps } from './bridge'
import type { HudState } from './protocol'

const sample: HudState = {
  role: 'CRIMINAL',
  life: 'ALIVE',
  cash: 1250,
  bag: 3,
  notoriety: 7,
  timer: { label: 'Bleeding out', seconds: 12 },
  prompt: 'Press E to loot',
  notifications: ['Bag secured'],
}

function makeDeps(): BridgeDeps {
  return { setHud: vi.fn(), navigate: vi.fn() }
}

describe('bridge', () => {
  beforeEach(() => {
    delete window.onIpcMessage
    delete window.sendIpcMessage
  })

  it('hud message calls setHud', () => {
    const deps = makeDeps()
    handleMessage(JSON.stringify({ type: 'hud', data: sample }), deps)
    expect(deps.setHud).toHaveBeenCalledWith(sample)
  })

  it('route message navigates', () => {
    const deps = makeDeps()
    handleMessage(JSON.stringify({ type: 'route', to: '/' }), deps)
    expect(deps.navigate).toHaveBeenCalledWith('/')
  })

  it('bad json is ignored', () => {
    const deps = makeDeps()
    expect(() => handleMessage('{oops', deps)).not.toThrow()
    expect(deps.setHud).not.toHaveBeenCalled()
    expect(deps.navigate).not.toHaveBeenCalled()
  })

  it('request resolves on ok reply', async () => {
    const sendIpcMessage = vi.fn()
    window.sendIpcMessage = sendIpcMessage
    const deps = makeDeps()
    const p = request('ping')
    const id = JSON.parse(sendIpcMessage.mock.calls[0][0]).id as number
    handleMessage(JSON.stringify({ type: 'reply', id, ok: true, data: { pong: true } }), deps)
    await expect(p).resolves.toEqual({ pong: true })
  })

  it('request rejects on error reply', async () => {
    const sendIpcMessage = vi.fn()
    window.sendIpcMessage = sendIpcMessage
    const deps = makeDeps()
    const p = request('ping')
    const id = JSON.parse(sendIpcMessage.mock.calls[0][0]).id as number
    handleMessage(
      JSON.stringify({ type: 'reply', id, ok: false, error: 'unknown_method' }),
      deps,
    )
    await expect(p).rejects.toThrow('unknown_method')
  })

  it('installBridge sends ready', () => {
    const sendIpcMessage = vi.fn()
    window.sendIpcMessage = sendIpcMessage
    const deps = makeDeps()
    installBridge(deps)
    expect(sendIpcMessage).toHaveBeenCalledWith(JSON.stringify({ type: 'ready' }))
  })
})
