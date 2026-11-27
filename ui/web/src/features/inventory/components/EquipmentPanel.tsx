import type { InventoryItem } from '@/lib/ipc/protocol'
import { EQUIPMENT, GAP, HEADER_GAP, TILE } from '../layout'
import { ItemTile } from './ItemTile'
import { PanelHeader } from './PanelHeader'

type Props = {
  gear: InventoryItem[]
  selectedUid: number | null
  onSelect: (uid: number) => void
}

const SLOTS = ['PRIMARY', 'SECONDARY', 'ARMOR', 'BAG', 'POUCH', 'POCKET', 'POCKET', 'POCKET', 'POCKET']

export function EquipmentPanel({ gear, selectedUid, onSelect }: Props) {
  const slot = (i: number, size: { w: number; h: number }, pocket = false) => (
    <ItemTile
      key={i}
      item={gear[i]}
      size={size}
      selected={gear[i] !== undefined && gear[i].uid === selectedUid}
      onSelect={onSelect}
      emptyLabel={pocket ? undefined : SLOTS[i]}
      emptyName={pocket ? 'Pocket' : undefined}
    />
  )
  return (
    <div className="flex flex-col">
      <PanelHeader title="EQUIPMENT" />
      <div className="flex flex-col" style={{ marginTop: HEADER_GAP, gap: EQUIPMENT.gap }}>
        {slot(0, EQUIPMENT.wide)}
        {slot(1, EQUIPMENT.wide)}
        <div className="flex" style={{ gap: EQUIPMENT.gap }}>
          {slot(2, EQUIPMENT.square)}
          {slot(3, EQUIPMENT.square)}
        </div>
      </div>
      <div className="text-sm font-bold uppercase" style={{ marginTop: 8, marginBottom: 6 }}>
        POUCH
      </div>
      <div className="flex" style={{ gap: EQUIPMENT.pouchGap }}>
        {slot(4, EQUIPMENT.pouch)}
        <div className="grid grid-cols-2" style={{ gap: GAP, width: 2 * TILE + GAP }}>
          {[5, 6, 7, 8].map((i) => slot(i, { w: TILE, h: TILE }, true))}
        </div>
      </div>
    </div>
  )
}
