import { beforeEach, describe, expect, it } from 'vitest'
import { DEMO_INVENTORY } from './demoInventory'
import { useInventoryStore } from './inventoryStore'

describe('inventoryStore.moveLocal', () => {
  beforeEach(() => {
    useInventoryStore.setState({ inventory: null, selectedUid: null })
  })

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
