import type { InventoryItem } from '@/lib/ipc/protocol'
import { formatMoney } from '@/lib/format'
import { RARITY_TILE, rarityOf } from './rarity'

type Props = {
  item?: InventoryItem
  size: { w: number; h: number }
  selected?: boolean
  onSelect?: (uid: number) => void
  emptyLabel?: string
  emptyName?: string
  dragRef?: (el: HTMLElement | null) => void
  dragProps?: Record<string, unknown>
  dragging?: boolean
}

export function ItemTile({
  item,
  size,
  selected,
  onSelect,
  emptyLabel,
  emptyName,
  dragRef,
  dragProps,
  dragging,
}: Props) {
  const style = { width: size.w, height: size.h }
  if (!item) {
    return (
      <button
        type="button"
        disabled
        aria-label={emptyLabel ?? emptyName ?? 'Empty slot'}
        style={style}
        className="relative grid place-items-center bg-black/25"
      >
        {emptyLabel ? (
          <span className="text-[10px] uppercase text-white/25">{emptyLabel}</span>
        ) : (
          <svg
            aria-hidden="true"
            width={26}
            height={26}
            viewBox="0 0 26 26"
            className="text-white/15"
            stroke="currentColor"
            strokeWidth={1.5}
          >
            <line x1={1} y1={1} x2={25} y2={25} />
            <line x1={25} y1={1} x2={1} y2={25} />
          </svg>
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
        <span className="absolute bottom-0.5 right-1 text-[11px] font-bold drop-shadow-[0_1px_1px_rgba(0,0,0,0.8)]">{formatMoney(item.value)}</span>
      )}
    </button>
  )
}
