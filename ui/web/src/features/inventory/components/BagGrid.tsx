import type { InventoryItem } from '@/lib/ipc/protocol'
import { GAP, TILE } from '../layout'
import { ItemTile } from './ItemTile'

type Props = {
  items: InventoryItem[]
  slots: number
  selectedUid: number | null
  onSelect: (uid: number) => void
}

export function BagGrid({ items, slots, selectedUid, onSelect }: Props) {
  const size = { w: TILE, h: TILE }
  return (
    <div className="grid grid-cols-6" style={{ gap: GAP }}>
      {Array.from({ length: slots }, (_, i) =>
        i < items.length ? (
          <ItemTile
            key={items[i].uid}
            item={items[i]}
            size={size}
            selected={items[i].uid === selectedUid}
            onSelect={onSelect}
          />
        ) : (
          <ItemTile key={`empty-${i}`} size={size} />
        ),
      )}
    </div>
  )
}
