import { formatMoney } from '@/lib/format'
import type { SearchItem } from '@/lib/ipc/protocol'

export function SearchItemRow({
  item,
  pending,
  onTake,
}: {
  item: SearchItem
  pending: boolean
  onTake: () => void
}) {
  const chip = item.source === 'bag' ? 'bg-amber-500/20 text-amber-300' : 'bg-white/10 text-white/70'
  return (
    <div className="flex h-[48px] items-center gap-3 px-3 border-b border-white/5">
      <span className="text-sm font-semibold flex-1 truncate">{item.label}</span>
      <span className={`text-[10px] uppercase tracking-wider rounded px-1.5 py-0.5 ${chip}`}>
        {item.source}
      </span>
      <span className="text-sm w-20 text-right">{formatMoney(item.value)}</span>
      <button
        type="button"
        className="pointer-events-auto rounded-sm bg-amber-400 px-3 py-1 text-xs font-bold text-zinc-900 hover:bg-amber-300 disabled:opacity-40"
        disabled={pending}
        onClick={onTake}
      >
        TAKE
      </button>
    </div>
  )
}
