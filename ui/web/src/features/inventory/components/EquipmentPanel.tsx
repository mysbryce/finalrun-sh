import type { InventoryItem } from '@/lib/ipc/protocol'
import { GAP, TILE } from '../layout'
import { ItemTile } from './ItemTile'
import { PanelHeader } from './PanelHeader'

type Props = {
  gear: InventoryItem[]
  selectedUid: number | null
  onSelect: (uid: number) => void
}

const SLOTS = ['PRIMARY', 'SECONDARY', 'ARMOR', 'BAG', 'POUCH', 'POUCH', 'POUCH', 'POUCH']

export function EquipmentPanel({ gear, selectedUid, onSelect }: Props) {
  const slot = (i: number, w: number, h: number) => (
    <ItemTile
      key={i}
      item={gear[i]}
      size={{ w, h }}
      selected={gear[i] !== undefined && gear[i].uid === selectedUid}
      onSelect={onSelect}
      emptyLabel={SLOTS[i]}
    />
  )
  return (
    <div className="flex flex-col gap-1">
      <PanelHeader title="EQUIPMENT" />
      {slot(0, 183, 87)}
      {slot(1, 183, 87)}
      <div className="flex gap-1">
        {slot(2, 90, 88)}
        {slot(3, 90, 88)}
      </div>
      <div className="mt-2 text-sm font-bold uppercase">POUCH</div>
      <div className="grid grid-cols-2" style={{ gap: GAP, width: 2 * TILE + GAP }}>
        {[4, 5, 6, 7].map((i) => slot(i, TILE, TILE))}
      </div>
    </div>
  )
}
