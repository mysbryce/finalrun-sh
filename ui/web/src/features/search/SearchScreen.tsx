import { useRef } from 'react'
import { useMutation } from '@tanstack/react-query'
import { useVirtualizer } from '@tanstack/react-virtual'
import { request } from '@/lib/ipc/bridge'
import { useSearchStore } from './searchStore'
import { SearchItemRow } from './components/SearchItemRow'

export function SearchScreen() {
  const search = useSearchStore((s) => s.search)
  const parentRef = useRef<HTMLDivElement>(null)
  const take = useMutation({
    mutationFn: (uid: number) => request('search.take', { target: search?.target, uid }),
  })
  const rows = useVirtualizer({
    count: search?.items.length ?? 0,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 48,
    overscan: 6,
  })
  if (!search) return null

  const close = () => {
    void request('search.close', { target: search.target })
  }

  return (
    <div className="pointer-events-auto absolute left-1/2 top-1/2 w-[460px] -translate-x-1/2 -translate-y-1/2 rounded-md bg-zinc-950/95 ring-1 ring-white/10 text-white">
      <div className="flex items-center justify-between px-4 py-3 border-b border-white/10">
        <span className="text-lg font-bold uppercase tracking-wider">{search.title}</span>
        <div className="flex items-center gap-3">
          <span className="text-[11px] text-white/60">{search.items.length} ITEMS</span>
          <button type="button" className="h-7 w-7 rounded-sm bg-white/10 hover:bg-white/20" onClick={close}>
            ×
          </button>
        </div>
      </div>
      {search.items.length === 0 ? (
        <div className="px-4 py-10 text-center text-sm text-white/60">Nothing left to take</div>
      ) : (
        <div ref={parentRef} className="h-[336px] overflow-y-auto">
          <div style={{ height: rows.getTotalSize(), position: 'relative' }}>
            {rows.getVirtualItems().map((row) => {
              const item = search.items[row.index]
              return (
                <div
                  key={item.uid}
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: row.size,
                    transform: `translateY(${row.start}px)`,
                  }}
                >
                  <SearchItemRow
                    item={item}
                    pending={take.isPending && take.variables === item.uid}
                    onTake={() => take.mutate(item.uid)}
                  />
                </div>
              )
            })}
          </div>
        </div>
      )}
      {take.isError && <div className="px-4 pb-2 text-xs text-red-400">{take.error.message}</div>}
      <div className="flex gap-4 px-4 py-2 border-t border-white/10 text-[11px] text-white/60">
        <span className="flex items-center gap-1.5">
          <span className="grid h-5 w-5 place-items-center rounded-sm bg-white text-[10px] font-bold text-zinc-900">
            Q
          </span>
          CLOSE
        </span>
      </div>
    </div>
  )
}
