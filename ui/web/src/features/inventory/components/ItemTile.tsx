import type { InventoryItem } from '@/lib/ipc/protocol'
import { formatMoney } from '@/lib/format'
import { RARITY_TILE, rarityOf } from '../rarity'

type Props = {
  item?: InventoryItem
  size: { w: number; h: number }
  selected?: boolean
  onSelect?: (uid: number) => void
  emptyLabel?: string
  dragRef?: (el: HTMLElement | null) => void
  dragProps?: Record<string, unknown>
  dragging?: boolean
}

export function ItemTile({ item, size, selected, onSelect, emptyLabel, dragRef, dragProps, dragging }: Props) {
  const style = { width: size.w, height: size.h }
  if (!item) {
    return (
      <button
        type="button"
        disabled
        aria-label={emptyLabel ?? 'Empty slot'}
        style={style}
        className={`relative grid place-items-center bg-zinc-800/50`}
      >
        {emptyLabel ? (
          <span className="text-[10px] uppercase text-white/25">{emptyLabel}</span>
        ) : (
          <span className="text-lg text-white/15">×</span>
        )}
      </button>
    )
  }
  return (
    <button
      type="button"
      ref={dragRef}
      {...dragProps}
      aria-label={item.label}
      style={style}
      onClick={() => onSelect?.(item.uid)}
      className={`relative ${RARITY_TILE[rarityOf(item.value)]} ${selected ? 'ring-2 ring-amber-400' : ''} ${dragging ? 'opacity-40' : ''}`}
    >
      <span className="absolute left-1 top-1 line-clamp-2 text-left text-[10px] font-semibold leading-tight">
        {item.label}
      </span>
      {item.value !== 0 && (
        <span className="absolute bottom-0.5 right-1 text-[11px] font-bold">{formatMoney(item.value)}</span>
      )}
    </button>
  )
}
