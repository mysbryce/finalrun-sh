import { beforeEach, describe, expect, it, vi } from 'vitest'
import { handleMessage, installBridge, request, type BridgeDeps } from './bridge'
import type { HudState } from './protocol'

const sample: HudState = {
  role: 'CRIMINAL',
  life: 'ALIVE',
  health: 75,
  maxHealth: 100,
  cash: 1250,
  bag: 3,
  notoriety: 7,
  heading: 312,
  timer: { label: 'Masking', seconds: 2 },
  interact: {
    title: 'Loot crate',
    actions: [
      { key: 'E', label: 'lockpick' },
      { key: 'V', label: 'smash' },
    ],
  },
  notifications: ['Bag secured'],
  self: { name: 'Player 2' },
  party: [
    {
      name: 'Player 3',
      health: 100,
      maxHealth: 100,
      life: 'ALIVE',
      leader: true,
      away: false,
    },
  ],
  hotbar: [{ label: 'Pistol' }, null, null, null, null, null],
  activeSlot: 0,
  net: { fps: 60, ping: 40 },
}

function makeDeps(): BridgeDeps {
  return { setHud: vi.fn(), navigate: vi.fn(), setSearch: vi.fn(), setInventory: vi.fn() }
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

  it('search message calls setSearch', () => {
    const deps = makeDeps()
    const view = { target: 7, title: 'Body', items: [{ uid: 1, id: 'a', label: 'A', value: 5, source: 'bag' }] }
    handleMessage(JSON.stringify({ type: 'search', data: view }), deps)
    expect(deps.setSearch).toHaveBeenCalledWith(view)
    handleMessage(JSON.stringify({ type: 'search', data: null }), deps)
    expect(deps.setSearch).toHaveBeenLastCalledWith(null)
  })

  it('inventory message calls setInventory', () => {
    const deps = makeDeps()
    const view = { cash: 5, bagValue: 0, bagSlots: 36, bag: [], gear: [] }
    handleMessage(JSON.stringify({ type: 'inventory', data: view }), deps)
    expect(deps.setInventory).toHaveBeenCalledWith(view)
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
