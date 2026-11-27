import type { InventoryItem, InventoryView } from '@/lib/ipc/protocol'

const bag: InventoryItem[] = [
  { uid: 1, id: 'jewelry', label: 'Jewelry', value: 0, source: 'bag', slot: 0, w: 1, h: 1 },
  { uid: 2, id: 'electronics', label: 'Electronics', value: 120, source: 'bag', slot: 1, w: 2, h: 1 },
  { uid: 3, id: 'cash_box', label: 'Cash box', value: 300, source: 'bag', slot: 3, w: 2, h: 2 },
  { uid: 6, id: 'lockpick', label: 'Lockpick', value: 800, source: 'bag', slot: 5, w: 1, h: 1 },
  { uid: 7, id: 'drill', label: 'Drill', value: 1500, source: 'bag', slot: 11, w: 1, h: 3 },
  { uid: 4, id: 'gold_bar', label: 'Gold bar', value: 300, source: 'bag', slot: 12, w: 2, h: 1 },
  { uid: 5, id: 'painting', label: 'Painting', value: 450, source: 'bag', slot: 14, w: 2, h: 3 },
  { uid: 8, id: 'phone', label: 'Phone', value: 60, source: 'bag', slot: 18, w: 1, h: 2 },
]

export const DEMO_INVENTORY: InventoryView = {
  cash: 79900,
  bagValue: bag.reduce((sum, i) => sum + i.value, 0),
  bagSlots: 54,
  bag,
  gear: [
    { uid: 101, id: 'cop_pistol', label: 'Cop pistol', value: 0, source: 'gear', slot: -1, w: 1, h: 1 },
    { uid: 102, id: 'cop_radio', label: 'Cop radio', value: 0, source: 'gear', slot: -1, w: 1, h: 1 },
    { uid: 103, id: 'cop_vest', label: 'Cop vest', value: 0, source: 'gear', slot: -1, w: 1, h: 1 },
  ],
}
