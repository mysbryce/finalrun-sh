import type { SearchView } from '@/lib/ipc/protocol'

const FOOTPRINTS: ReadonlyArray<readonly [number, number]> = [
  [1, 1],
  [1, 2],
  [2, 1],
  [2, 2],
]

export const DEMO_SEARCH: SearchView = {
  target: 7,
  title: 'Body of Player 7',
  items: Array.from({ length: 40 }, (_, i) => ({
    uid: i + 1,
    id: `item_${i + 1}`,
    label: `Item ${i + 1}`,
    value: (i + 1) * 50,
    source: i % 3 === 0 ? 'gear' : 'bag',
    w: FOOTPRINTS[i % FOOTPRINTS.length][0],
    h: FOOTPRINTS[i % FOOTPRINTS.length][1],
    slot: -1,
  })),
}
