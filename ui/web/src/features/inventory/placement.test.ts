import { describe, expect, it } from 'vitest'
import type { InventoryItem } from '@/lib/ipc/protocol'
import { moveBagItem, placeBagItems, slotFromDropId } from './placement'

const item = (uid: number, slot: number): InventoryItem => ({
  uid,
  id: `item_${uid}`,
  label: `Item ${uid}`,
  value: 0,
  source: 'bag',
  slot,
})

describe('placeBagItems', () => {
  it('puts items at valid slots', () => {
    const cells = placeBagItems([item(1, 0), item(2, 8)], 36)
    expect(cells).toHaveLength(36)
    expect(cells[0]?.uid).toBe(1)
    expect(cells[8]?.uid).toBe(2)
    expect(cells[6]).toBeNull()
  })

  it('sends a duplicate slot to the first free cell', () => {
    const cells = placeBagItems([item(1, 0), item(2, 0)], 36)
    expect(cells[0]?.uid).toBe(1)
    expect(cells[1]?.uid).toBe(2)
  })

  it('sends slot -1 and slot >= slots to the first free cell', () => {
    const cells = placeBagItems([item(1, 0), item(2, -1), item(3, 36)], 36)
    expect(cells[0]?.uid).toBe(1)
    expect(cells[1]?.uid).toBe(2)
    expect(cells[2]?.uid).toBe(3)
  })
})

describe('moveBagItem', () => {
  const bag = [item(1, 0), item(2, 1)]

  it('moves to an empty slot', () => {
    const moved = moveBagItem(bag, 1, 5, 36)
    expect(moved.find((i) => i.uid === 1)?.slot).toBe(5)
    expect(moved.find((i) => i.uid === 2)?.slot).toBe(1)
  })

  it('swaps with the item in an occupied slot', () => {
    const moved = moveBagItem(bag, 1, 1, 36)
    expect(moved.find((i) => i.uid === 1)?.slot).toBe(1)
    expect(moved.find((i) => i.uid === 2)?.slot).toBe(0)
  })

  it('returns the same array for an unknown uid or an out-of-range slot', () => {
    expect(moveBagItem(bag, 99, 3, 36)).toBe(bag)
    expect(moveBagItem(bag, 1, 36, 36)).toBe(bag)
  })
})

describe('slotFromDropId', () => {
  it('parses slot ids only', () => {
    expect(slotFromDropId('slot-7')).toBe(7)
    expect(slotFromDropId('7')).toBeNull()
    expect(slotFromDropId(undefined)).toBeNull()
  })
})
