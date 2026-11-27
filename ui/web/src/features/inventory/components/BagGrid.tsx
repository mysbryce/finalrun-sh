import { useDraggable, useDroppable } from '@dnd-kit/core'
import type { InventoryItem } from '@/lib/ipc/protocol'
import { GAP, TILE } from '../layout'
import { placeBagItems } from '../placement'
import { ItemTile } from './ItemTile'

type Props = {
  items: InventoryItem[]
  slots: number
  selectedUid: number | null
  onSelect: (uid: number) => void
}

const SIZE = { w: TILE, h: TILE }

export function BagGrid({ items, slots, selectedUid, onSelect }: Props) {
  const cells = placeBagItems(items, slots)
  return (
    <div className="grid grid-cols-6" style={{ gap: GAP }}>
      {cells.map((item, i) => (
        <BagCell
          key={item ? item.uid : `empty-${i}`}
          index={i}
          item={item}
          selected={item !== null && item.uid === selectedUid}
          onSelect={onSelect}
        />
      ))}
    </div>
  )
}

type CellProps = {
  index: number
  item: InventoryItem | null
  selected: boolean
  onSelect: (uid: number) => void
}

function BagCell({ index, item, selected, onSelect }: CellProps) {
  const { setNodeRef, isOver } = useDroppable({ id: `slot-${index}` })
  return (
    <div ref={setNodeRef} style={{ width: TILE, height: TILE }}>
      {item ? (
        <DraggableTile item={item} selected={selected} onSelect={onSelect} dropOver={isOver} />
      ) : (
        <ItemTile size={SIZE} dropOver={isOver} />
      )}
    </div>
  )
}

type TileProps = {
  item: InventoryItem
  selected: boolean
  onSelect: (uid: number) => void
  dropOver: boolean
}

function DraggableTile({ item, selected, onSelect, dropOver }: TileProps) {
  const { setNodeRef, attributes, listeners, isDragging } = useDraggable({ id: item.uid })
  return (
    <ItemTile
      item={item}
      size={SIZE}
      selected={selected}
      onSelect={onSelect}
      dragRef={setNodeRef}
      dragProps={{ ...attributes, ...listeners }}
      dragging={isDragging}
      dropOver={dropOver}
    />
  )
}
