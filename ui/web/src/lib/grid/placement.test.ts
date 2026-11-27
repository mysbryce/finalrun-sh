import { describe, expect, it } from 'vitest'
import type { InventoryItem } from '@/lib/ipc/protocol'
import { footprint, moveBagItem, occupancy, packRows, placeBagItems, slotFromDropId, targetSlot } from './placement'

const SLOTS = 54
const COLS = 6

const item = (uid: number, slot: number, w = 1, h = 1): InventoryItem => ({
  uid,
  id: `item_${uid}`,
  label: `Item ${uid}`,
  value: 0,
  source: 'bag',
  slot,
  w,
  h,
})

const slotOf = (items: InventoryItem[], uid: number) => items.find((i) => i.uid === uid)?.slot

describe('footprint', () => {
  it('lists covered cells, or [] when outside the grid', () => {
    expect(footprint(0, 2, 3, COLS, SLOTS)).toEqual([0, 1, 6, 7, 12, 13])
    expect(footprint(5, 2, 1, COLS, SLOTS)).toEqual([])
    expect(footprint(48, 1, 2, COLS, SLOTS)).toEqual([])
  })
})

describe('placeBagItems', () => {
  it('moves an overlapping item to the first fit', () => {
    const placed = placeBagItems([item(1, 0, 2, 2), item(2, 7)], SLOTS, COLS)
    expect(placed.find((p) => p.item.uid === 1)?.slot).toBe(0)
    expect(placed.find((p) => p.item.uid === 2)?.slot).toBe(2)
  })

  it('sends slot -1 to the first fit', () => {
    const placed = placeBagItems([item(1, 0), item(2, -1)], SLOTS, COLS)
    expect(placed.find((p) => p.item.uid === 2)?.slot).toBe(1)
  })

  it('leaves out an item that fits nowhere', () => {
    const items: InventoryItem[] = []
    for (let i = 0; i < 9; i++) {
      const col = (i % 3) * 2
      const row = Math.floor(i / 3) * 3
      items.push(item(i + 1, row * COLS + col, 2, 3))
    }
    items.push(item(100, 0))
    const placed = placeBagItems(items, SLOTS, COLS)
    expect(placed).toHaveLength(9)
    expect(placed.some((p) => p.item.uid === 100)).toBe(false)
  })
})

describe('occupancy', () => {
  it('marks every cell an item covers', () => {
    const occ = occupancy(placeBagItems([item(1, 0, 2, 2)], SLOTS, COLS), SLOTS, COLS)
    expect(occ[0]).toBe(1)
    expect(occ[1]).toBe(1)
    expect(occ[6]).toBe(1)
    expect(occ[7]).toBe(1)
    expect(occ[2]).toBeNull()
  })
})

describe('moveBagItem', () => {
  it('moves a 1x1 to an empty slot', () => {
    const bag = [item(1, 0), item(2, 1)]
    const moved = moveBagItem(bag, 1, 5, SLOTS, COLS)
    expect(slotOf(moved, 1)).toBe(5)
    expect(slotOf(moved, 2)).toBe(1)
  })

  it('swaps a 1x1 onto a 1x1', () => {
    const bag = [item(1, 0), item(2, 1)]
    const moved = moveBagItem(bag, 1, 1, SLOTS, COLS)
    expect(slotOf(moved, 1)).toBe(1)
    expect(slotOf(moved, 2)).toBe(0)
  })

  it('moves a 2x2 over its own old cells', () => {
    const bag = [item(1, 0, 2, 2)]
    const moved = moveBagItem(bag, 1, 7, SLOTS, COLS)
    expect(slotOf(moved, 1)).toBe(7)
  })

  it('rejects a move past the edge', () => {
    const bag = [item(1, 0, 2, 2)]
    expect(moveBagItem(bag, 1, 5, SLOTS, COLS)).toBe(bag)
  })

  it('swaps a 2x1 onto a 2x2', () => {
    const bag = [item(3, 0, 2, 2), item(5, 2, 2, 1)]
    const moved = moveBagItem(bag, 5, 0, SLOTS, COLS)
    expect(slotOf(moved, 5)).toBe(0)
    expect(slotOf(moved, 3)).toBe(2)
  })

  it('rejects a 2x1 onto two 1x1 items', () => {
    const bag = [item(1, 0), item(2, 1), item(5, 2, 2, 1)]
    expect(moveBagItem(bag, 5, 0, SLOTS, COLS)).toBe(bag)
  })

  it('returns the same array for an unknown uid', () => {
    const bag = [item(1, 0)]
    expect(moveBagItem(bag, 99, 3, SLOTS, COLS)).toBe(bag)
  })
})

describe('targetSlot', () => {
  it('offsets by the grab cell', () => {
    expect(targetSlot(14, 1, 1, COLS)).toBe(7)
    expect(targetSlot(12, 1, 0, COLS)).toBeNull()
    expect(targetSlot(3, 0, 1, COLS)).toBeNull()
  })
})

describe('slotFromDropId', () => {
  it('parses slot ids only', () => {
    expect(slotFromDropId('slot-7')).toBe(7)
    expect(slotFromDropId('7')).toBeNull()
    expect(slotFromDropId(undefined)).toBeNull()
  })
})

describe('packRows', () => {
  const box = (uid: number, w: number, h: number) => ({ uid, w, h })

  it('packs row-first in input order', () => {
    const { packed } = packRows([box(1, 1, 1), box(2, 2, 1), box(3, 1, 1)], COLS, 9)
    expect(packed.map((p) => p.slot)).toEqual([0, 1, 3])
  })

  it('puts a 2x2 after a 6x1 at slot 6', () => {
    const { packed } = packRows([box(1, 6, 1), box(2, 2, 2)], COLS, 9)
    expect(packed.find((p) => p.item.uid === 2)?.slot).toBe(6)
  })

  it('adds rows as needed', () => {
    const items = Array.from({ length: 12 }, (_, i) => box(i + 1, 6, 1))
    expect(packRows(items, COLS, 9).rows).toBe(12)
  })

  it('gives minRows for empty input', () => {
    expect(packRows([], COLS, 9)).toEqual({ packed: [], rows: 9 })
  })

  it('skips an item wider than cols', () => {
    const { packed } = packRows([box(1, 7, 1), box(2, 1, 1)], COLS, 9)
    expect(packed).toEqual([{ item: box(2, 1, 1), slot: 0 }])
  })
})
