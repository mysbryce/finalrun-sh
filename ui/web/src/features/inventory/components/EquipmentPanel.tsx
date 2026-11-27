import type { InventoryItem } from '@/lib/ipc/protocol'
import { EQUIP_COL, EQUIP_SLOTS, GAP, TILE } from '../layout'
import { ItemTile } from './ItemTile'

type Props = {
  gear: InventoryItem[]
  selectedUid: number | null
  onSelect: (uid: number) => void
}

const SLOTS = ['PRIMARY', 'SECONDARY', 'ARMOR', 'BAG', 'POUCH', 'POCKET', 'POCKET', 'POCKET', 'POCKET']

type Box = { left: number; top: number; w: number; h: number }

export function EquipmentPanel({ gear, selectedUid, onSelect }: Props) {
  const tile = (i: number, size: { w: number; h: number }, pocket = false) => (
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
  const slot = (i: number, box: Box) => (
    <div className="absolute" style={{ left: box.left, top: box.top }}>
      {tile(i, { w: box.w, h: box.h })}
    </div>
  )
  return (
    <div className="relative" style={{ width: EQUIP_COL.width, height: EQUIP_SLOTS.pouch.top + EQUIP_SLOTS.pouch.h }}>
      {slot(0, EQUIP_SLOTS.primary)}
      {slot(1, EQUIP_SLOTS.secondary)}
      {slot(2, EQUIP_SLOTS.armor)}
      {slot(3, EQUIP_SLOTS.bag)}
      <div
        className="absolute text-xs font-bold uppercase text-white/70"
        style={{ left: EQUIP_SLOTS.pouchLabel.left, top: EQUIP_SLOTS.pouchLabel.top }}
      >
        POUCH
      </div>
      {slot(4, EQUIP_SLOTS.pouch)}
      <div className="absolute" style={{ left: EQUIP_SLOTS.pockets.left, top: EQUIP_SLOTS.pockets.top }}>
        <div className="grid grid-cols-2" style={{ gap: GAP }}>
          {[5, 6, 7, 8].map((i) => tile(i, { w: TILE, h: TILE }, true))}
        </div>
      </div>
    </div>
  )
}
