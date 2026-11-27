import { beforeEach, describe, expect, it } from 'vitest'
import { DEMO_INVENTORY } from './demoInventory'
import { useInventoryStore } from './inventoryStore'

describe('inventoryStore.moveLocal', () => {
  beforeEach(() => {
    useInventoryStore.setState({ inventory: null, selectedUid: null })
  })

  it('swaps the first two items, then setInventory replaces the optimistic state', () => {
    const { setInventory, moveLocal } = useInventoryStore.getState()
    setInventory(DEMO_INVENTORY)
    const first = DEMO_INVENTORY.bag.find((i) => i.slot === 0)!
    const second = DEMO_INVENTORY.bag.find((i) => i.slot === 1)!
    moveLocal(first.uid, 1)
    const bag = useInventoryStore.getState().inventory!.bag
    expect(bag.find((i) => i.uid === first.uid)?.slot).toBe(1)
    expect(bag.find((i) => i.uid === second.uid)?.slot).toBe(0)

    setInventory(DEMO_INVENTORY)
    expect(useInventoryStore.getState().inventory).toBe(DEMO_INVENTORY)
  })
})
