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

  it('new snapshot types reach their setters', () => {
    const deps: BridgeDeps = {
      ...makeDeps(),
      setBoot: vi.fn(),
      setLobby: vi.fn(),
      setParty: vi.fn(),
      setSettings: vi.fn(),
      setTransfer: vi.fn(),
      setGameOverlay: vi.fn(),
    }
    const cases: Array<[string, unknown, unknown]> = [
      ['boot', { phase: 'title', buildId: 'dev' }, deps.setBoot],
      ['lobby', { canPlay: true }, deps.setLobby],
      ['party', { members: [] }, deps.setParty],
      ['settings', { revision: 1 }, deps.setSettings],
      ['transfer', { mapName: 'Motel' }, deps.setTransfer],
      ['game_overlay', { kind: 'death', receiptId: 'r1' }, deps.setGameOverlay],
    ]
    for (const [type, data, setter] of cases) {
      handleMessage(JSON.stringify({ type, data }), deps)
      expect(setter).toHaveBeenCalledWith(data)
    }
  })

  it('nullable snapshot types pass null', () => {
    const deps: BridgeDeps = {
      ...makeDeps(),
      setParty: vi.fn(),
      setTransfer: vi.fn(),
      setGameOverlay: vi.fn(),
    }
    handleMessage(JSON.stringify({ type: 'party', data: null }), deps)
    handleMessage(JSON.stringify({ type: 'transfer', data: null }), deps)
    handleMessage(JSON.stringify({ type: 'game_overlay', data: null }), deps)
    expect(deps.setParty).toHaveBeenCalledWith(null)
    expect(deps.setTransfer).toHaveBeenCalledWith(null)
    expect(deps.setGameOverlay).toHaveBeenCalledWith(null)
  })

  it('new type without a setter is ignored', () => {
    const deps = makeDeps()
    for (const type of ['boot', 'lobby', 'party', 'settings', 'transfer', 'game_overlay']) {
      expect(() => handleMessage(JSON.stringify({ type, data: {} }), deps)).not.toThrow()
    }
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
