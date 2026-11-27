import { beforeEach, describe, expect, it } from 'vitest'
import { DEMO_INVENTORY } from './demoInventory'
import { useInventoryStore } from './inventoryStore'

const reset = () =>
  useInventoryStore.setState({ inventory: null, selectedUid: null, committed: null, notice: null, seq: 0 })

describe('inventoryStore.moveLocal', () => {
  beforeEach(reset)

  it('swaps two 1x1 items, then setInventory replaces the optimistic state', () => {
    const { setInventory, moveLocal } = useInventoryStore.getState()
    setInventory(DEMO_INVENTORY)
    const first = DEMO_INVENTORY.bag.find((i) => i.id === 'jewelry')!
    const second = DEMO_INVENTORY.bag.find((i) => i.id === 'lockpick')!
    moveLocal(first.uid, second.slot)
    const bag = useInventoryStore.getState().inventory!.bag
    expect(bag.find((i) => i.uid === first.uid)?.slot).toBe(second.slot)
    expect(bag.find((i) => i.uid === second.uid)?.slot).toBe(first.slot)

    setInventory(DEMO_INVENTORY)
    expect(useInventoryStore.getState().inventory).toBe(DEMO_INVENTORY)
  })
})

describe('inventoryStore.revert', () => {
  beforeEach(reset)

  it('restores committed and sets notice', () => {
    const view = structuredClone(DEMO_INVENTORY)
    const { setInventory, moveLocal, revert } = useInventoryStore.getState()
    setInventory(view)
    moveLocal(1, 5)
    expect(useInventoryStore.getState().inventory).not.toBe(view)
    revert('Move could not be confirmed.')
    const s = useInventoryStore.getState()
    expect(s.inventory).toBe(view)
    expect(s.notice).toBe('Move could not be confirmed.')
  })

  it('changes nothing when committed is null', () => {
    const view = structuredClone(DEMO_INVENTORY)
    useInventoryStore.setState({ inventory: view })
    useInventoryStore.getState().revert('x')
    const s = useInventoryStore.getState()
    expect(s.inventory).toBe(view)
    expect(s.notice).toBeNull()
  })

  it('setInventory clears notice and bumps seq', () => {
    useInventoryStore.setState({ notice: 'old', seq: 3 })
    useInventoryStore.getState().setInventory(structuredClone(DEMO_INVENTORY))
    const s = useInventoryStore.getState()
    expect(s.notice).toBeNull()
    expect(s.seq).toBe(4)
  })
})
