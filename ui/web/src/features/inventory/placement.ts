import type { InventoryItem } from '@/lib/ipc/protocol'

export type Placed = { item: InventoryItem; slot: number }

// Cells covered by a w x h item at `slot`; [] when any part is outside the grid.
export function footprint(slot: number, w: number, h: number, cols: number, slots: number): number[] {
  if (!Number.isInteger(slot) || slot < 0 || slot >= slots) return []
  if (!Number.isInteger(w) || !Number.isInteger(h) || w < 1 || h < 1) return []
  const rows = Math.ceil(slots / cols)
  const col = slot % cols
  const row = Math.floor(slot / cols)
  if (col + w > cols || row + h > rows) return []
  const cells: number[] = []
  for (let r = row; r < row + h; r++) {
    for (let c = col; c < col + w; c++) {
      const cell = r * cols + c
      if (cell >= slots) return []
      cells.push(cell)
    }
  }
  return cells
}

// Items with a valid, non-overlapping slot keep it (first come first served);
// the others take the first slot where they fit; items that fit nowhere are left out.
export function placeBagItems(items: InventoryItem[], slots: number, cols: number): Placed[] {
  const used: boolean[] = Array.from({ length: slots }, () => false)
  const placed: Placed[] = []
  const rest: InventoryItem[] = []
  const fits = (cells: number[]) => cells.length > 0 && cells.every((c) => !used[c])
  const take = (item: InventoryItem, slot: number, cells: number[]) => {
    for (const c of cells) used[c] = true
    placed.push({ item, slot })
  }
  for (const item of items) {
    const cells = footprint(item.slot, item.w, item.h, cols, slots)
    if (fits(cells)) take(item, item.slot, cells)
    else rest.push(item)
  }
  for (const item of rest) {
    for (let s = 0; s < slots; s++) {
      const cells = footprint(s, item.w, item.h, cols, slots)
      if (fits(cells)) {
        take(item, s, cells)
        break
      }
    }
  }
  return placed
}

// uid covering each cell, or null.
export function occupancy(placed: Placed[], slots: number, cols: number): (number | null)[] {
  const cells: (number | null)[] = Array.from({ length: slots }, () => null)
  for (const p of placed) {
    for (const c of footprint(p.slot, p.item.w, p.item.h, cols, slots)) cells[c] = p.item.uid
  }
  return cells
}

// Optimistic move with the protocol's move rule (works on placeBagItems' result);
// returns `items` itself (same reference) when nothing changes or the move is rejected.
export function moveBagItem(
  items: InventoryItem[],
  uid: number,
  slot: number,
  slots: number,
  cols: number,
): InventoryItem[] {
  const placed = placeBagItems(items, slots, cols)
  const x = placed.find((p) => p.item.uid === uid)
  if (!x) return items
  const fpX = footprint(slot, x.item.w, x.item.h, cols, slots)
  if (fpX.length === 0) return items
  const occ = occupancy(placed, slots, cols)
  const others = new Set<number>()
  for (const c of fpX) {
    const o = occ[c]
    if (o !== null && o !== uid) others.add(o)
  }
  if (others.size === 0) {
    if (slot === x.slot) return items
    return items.map((i) => (i.uid === uid ? { ...i, slot } : i))
  }
  if (others.size !== 1) return items
  const bUid = [...others][0]
  const b = placed.find((p) => p.item.uid === bUid)
  if (!b) return items
  const fromSlot = x.slot
  const fpB = footprint(fromSlot, b.item.w, b.item.h, cols, slots)
  if (fpB.length === 0) return items
  const setX = new Set(fpX)
  if (fpB.some((c) => setX.has(c))) return items
  const rest = occupancy(
    placed.filter((p) => p.item.uid !== uid && p.item.uid !== bUid),
    slots,
    cols,
  )
  if (fpX.some((c) => rest[c] !== null) || fpB.some((c) => rest[c] !== null)) return items
  return items.map((i) => {
    if (i.uid === uid) return { ...i, slot }
    if (i.uid === bUid) return { ...i, slot: fromSlot }
    return i
  })
}

// Top-left slot when the pointer is over `pointerSlot` and the item was grabbed at
// cell (offCol, offRow) of itself; null when that would start left of column 0 or above row 0.
export function targetSlot(pointerSlot: number, offCol: number, offRow: number, cols: number): number | null {
  const col = (pointerSlot % cols) - offCol
  const row = Math.floor(pointerSlot / cols) - offRow
  if (col < 0 || row < 0) return null
  return row * cols + col
}

// "slot-7" -> 7, anything else -> null.
export function slotFromDropId(id: string | number | null | undefined): number | null {
  if (typeof id !== 'string') return null
  const m = /^slot-(\d+)$/.exec(id)
  return m ? Number(m[1]) : null
}
