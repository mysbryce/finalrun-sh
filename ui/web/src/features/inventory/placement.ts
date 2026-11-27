import type { InventoryItem } from '@/lib/ipc/protocol'

// Grid cells for the bag: an item sits at its slot when the slot is valid and
// free; anything else takes the first free cell (server data is the truth,
// this only guards against bad or duplicate slots).
export function placeBagItems(items: InventoryItem[], slots: number): (InventoryItem | null)[] {
  const cells: (InventoryItem | null)[] = Array.from({ length: slots }, () => null)
  const rest: InventoryItem[] = []
  for (const item of items) {
    const s = item.slot
    if (Number.isInteger(s) && s >= 0 && s < slots && cells[s] === null) cells[s] = item
    else rest.push(item)
  }
  for (const item of rest) {
    const free = cells.indexOf(null)
    if (free === -1) break
    cells[free] = item
  }
  return cells
}

// Optimistic move: returns a new bag with `uid` at `slot`, swapping with the
// item already there. Unknown uid or slot outside 0..slots-1 returns `items` unchanged.
export function moveBagItem(items: InventoryItem[], uid: number, slot: number, slots: number): InventoryItem[] {
  if (!Number.isInteger(slot) || slot < 0 || slot >= slots) return items
  const cells = placeBagItems(items, slots)
  const from = cells.findIndex((c) => c?.uid === uid)
  if (from === -1) return items
  const other = cells[slot]
  return items.map((i) => {
    if (i.uid === uid) return { ...i, slot }
    if (other && i.uid === other.uid) return { ...i, slot: from }
    return i
  })
}

// "slot-7" -> 7, anything else -> null.
export function slotFromDropId(id: string | number | null | undefined): number | null {
  if (typeof id !== 'string') return null
  const m = /^slot-(\d+)$/.exec(id)
  return m ? Number(m[1]) : null
}
