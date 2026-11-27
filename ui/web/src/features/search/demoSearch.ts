import type { SearchView } from '@/lib/ipc/protocol'

export const DEMO_SEARCH: SearchView = {
  target: 7,
  title: 'Body of Player 7',
  items: Array.from({ length: 40 }, (_, i) => ({
    uid: i + 1,
    id: `item_${i + 1}`,
    label: `Item ${i + 1}`,
    value: (i + 1) * 50,
    source: i % 3 === 0 ? 'gear' : 'bag',
  })),
}
