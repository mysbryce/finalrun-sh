import type { InventoryItem, InventoryView } from '@/lib/ipc/protocol'

const bag: InventoryItem[] = [
  { uid: 1, id: 'jewelry', label: 'Jewelry', value: 0, source: 'bag', slot: 0 },
  { uid: 2, id: 'electronics', label: 'Electronics', value: 120, source: 'bag', slot: 1 },
  { uid: 3, id: 'cash_box', label: 'Cash box', value: 300, source: 'bag', slot: 2 },
  { uid: 4, id: 'gold_bar', label: 'Gold bar', value: 300, source: 'bag', slot: 3 },
  { uid: 5, id: 'painting', label: 'Painting', value: 450, source: 'bag', slot: 4 },
  { uid: 6, id: 'lockpick', label: 'Lockpick', value: 800, source: 'bag', slot: 5 },
  { uid: 7, id: 'drill', label: 'Drill', value: 1500, source: 'bag', slot: 8 },
  { uid: 8, id: 'phone', label: 'Phone', value: 60, source: 'bag', slot: 13 },
]

export const DEMO_INVENTORY: InventoryView = {
  cash: 79900,
  bagValue: bag.reduce((sum, i) => sum + i.value, 0),
  bagSlots: 36,
  bag,
  gear: [
    { uid: 101, id: 'cop_pistol', label: 'Cop pistol', value: 0, source: 'gear', slot: -1 },
    { uid: 102, id: 'cop_radio', label: 'Cop radio', value: 0, source: 'gear', slot: -1 },
    { uid: 103, id: 'cop_vest', label: 'Cop vest', value: 0, source: 'gear', slot: -1 },
  ],
}
