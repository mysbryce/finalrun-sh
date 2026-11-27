import type { InventoryItem } from '@/lib/ipc/protocol'
import { formatMoney } from '@/lib/format'
import { BAG_GRID, HEADER_GAP } from '../layout'
import { RARITY_TILE, rarityOf } from '../rarity'
import { PanelHeader } from './PanelHeader'

export function DetailsPanel({ item }: { item?: InventoryItem }) {
  return (
    <div>
      <PanelHeader title="DETAILS" />
      <div className="bg-black/20 p-4" style={{ marginTop: HEADER_GAP, height: BAG_GRID.height }}>
        {!item ? (
          <span className="text-sm text-white/50">Select an item</span>
        ) : (
          <div className="flex flex-col items-start gap-2">
            <div className={`h-[120px] w-[120px] ${RARITY_TILE[rarityOf(item.value)]}`} aria-hidden="true" />
            <div className="text-xl font-bold">{item.label}</div>
            <div className="text-sm font-semibold">{formatMoney(item.value)}</div>
            <div className="flex items-center gap-2">
              <span className="rounded-sm bg-white/10 px-2 py-0.5 text-xs font-bold uppercase">
                {item.source === 'gear' ? 'GEAR' : 'BAG'}
              </span>
              <span className="text-xs uppercase text-white/60">{rarityOf(item.value)}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
