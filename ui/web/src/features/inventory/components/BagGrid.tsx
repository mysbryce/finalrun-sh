import { useDraggable, useDroppable } from '@dnd-kit/core'
import type { InventoryItem } from '@/lib/ipc/protocol'
import { BAG_COLUMNS, cellBox } from '@/lib/grid/gridLayout'
import { occupancy, placeBagItems } from '@/lib/grid/placement'
import { ItemTile } from '@/lib/grid/ItemTile'

type Props = {
  items: InventoryItem[]
  slots: number
  selectedUid: number | null
  onSelect: (uid: number) => void
  preview?: { slot: number; w: number; h: number; ok: boolean } | null
}

export function BagGrid({ items, slots, selectedUid, onSelect, preview }: Props) {
  const rows = Math.ceil(slots / BAG_COLUMNS)
  const placed = placeBagItems(items, slots, BAG_COLUMNS)
  const occ = occupancy(placed, slots, BAG_COLUMNS)
  const outer = cellBox(0, BAG_COLUMNS, rows)
  return (
    <div className="relative" style={{ width: outer.width, height: outer.height }}>
      {occ.map((uid, i) => (
        <BagCell key={`cell-${i}`} index={i} covered={uid !== null} />
      ))}
      {placed.map(({ item, slot }) => (
        <DraggableTile
          key={item.uid}
          item={item}
          slot={slot}
          selected={item.uid === selectedUid}
          onSelect={onSelect}
        />
      ))}
      {preview && (
        <div
          className={`pointer-events-none absolute ${
            preview.ok ? 'ring-2 ring-inset ring-white/70 bg-white/10' : 'ring-2 ring-inset ring-red-500/80 bg-red-500/15'
          }`}
          style={cellBox(preview.slot, preview.w, preview.h)}
        />
      )}
    </div>
  )
}

type CellProps = {
  index: number
  covered: boolean
}

function BagCell({ index, covered }: CellProps) {
  const { setNodeRef } = useDroppable({ id: `slot-${index}` })
  const box = cellBox(index)
  return (
    <div ref={setNodeRef} className="absolute" style={box}>
      {covered ? <div /> : <ItemTile size={{ w: box.width, h: box.height }} />}
    </div>
  )
}

type TileProps = {
  item: InventoryItem
  slot: number
  selected: boolean
  onSelect: (uid: number) => void
}

function DraggableTile({ item, slot, selected, onSelect }: TileProps) {
  const { setNodeRef, attributes, listeners, isDragging } = useDraggable({ id: item.uid })
  const box = cellBox(slot, item.w, item.h)
  return (
    <div className="absolute" style={box}>
      <ItemTile
        item={item}
        size={{ w: box.width, h: box.height }}
        selected={selected}
        onSelect={onSelect}
        dragRef={setNodeRef}
        dragProps={{ ...attributes, ...listeners }}
        dragging={isDragging}
      />
    </div>
  )
}
