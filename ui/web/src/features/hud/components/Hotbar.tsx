import type { HotbarSlot } from '@/lib/ipc/protocol'
import { formatMoney } from '@/lib/format'

export function Hotbar({
  slots,
  active,
  bag,
}: {
  slots: HotbarSlot[]
  active: number
  bag: number
}) {
  return (
    <div className="absolute right-6 bottom-6 flex items-end gap-1.5">
      {slots.map((slot, i) => (
        <div key={i} className="flex flex-col items-center gap-1">
          <div
            className={`relative flex items-start justify-center rounded-md bg-zinc-950/60 p-1 ${
              i < 2 ? 'w-36 h-16' : 'w-12 h-16'
            } ${i === active ? 'ring-2 ring-amber-400' : 'ring-1 ring-white/10'}`}
          >
            {slot ? (
              <span className="text-xs font-semibold">{slot.label}</span>
            ) : (
              <span className="text-xs font-semibold text-white/20">×</span>
            )}
            {slot?.count !== undefined && (
              <span className="absolute bottom-1 right-1 text-[10px]">{slot.count}</span>
            )}
          </div>
          <span className="text-[10px] text-white/60">{i + 1}</span>
        </div>
      ))}
      <div className="mx-1 h-12 w-px bg-white/20" />
      <div className="flex flex-col items-center gap-1">
        <div className="flex w-16 h-16 flex-col items-center justify-center rounded-md bg-zinc-950/60 ring-1 ring-white/10">
          <span className="text-[10px]">BAG</span>
          <span className="text-xs font-bold">{formatMoney(bag)}</span>
        </div>
        <span className="text-[10px] text-white/60">TAB</span>
      </div>
    </div>
  )
}
