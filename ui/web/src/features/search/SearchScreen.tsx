import { useEffect, useRef, useState } from 'react'
import { request } from '@/lib/ipc/bridge'
import { KeyHint } from '@/lib/ui/KeyHint'
import { useSearchStore } from './searchStore'
import { BodyGrid } from './components/BodyGrid'
import {
  BODY_VIEWPORT,
  FOOTER_CLOSE,
  FOOTER_ERROR,
  FOOTER_ROW,
  FOOTER_TAKE,
  SEARCH_COUNT,
  SEARCH_FOOTER,
  SEARCH_HEADER,
  SEARCH_PANEL,
  SEARCH_TITLE,
} from './layout'

function takeError(e: unknown): string {
  const code = e instanceof Error ? e.message : ''
  if (code === 'no_search') return 'Search closed.'
  if (code === 'timeout') return 'No answer from the game.'
  return 'Could not take the item.'
}

export function SearchScreen() {
  const search = useSearchStore((s) => s.search)
  const pendingRef = useRef<Set<number>>(new Set())
  const [pending, setPending] = useState<ReadonlySet<number>>(pendingRef.current)
  const [error, setError] = useState<string | null>(null)

  const updatePending = (next: Set<number>) => {
    pendingRef.current = next
    setPending(next)
  }

  // A new snapshot clears the error and drops pending uids that are gone.
  useEffect(() => {
    setError(null)
    const present = new Set(search?.items.map((i) => i.uid) ?? [])
    const next = new Set([...pendingRef.current].filter((uid) => present.has(uid)))
    if (next.size !== pendingRef.current.size) updatePending(next)
  }, [search])

  // ponytail: "Bag full" shows as a HUD notification after the search closes.
  const take = (uid: number) => {
    if (!search || pendingRef.current.has(uid)) return
    setError(null)
    updatePending(new Set(pendingRef.current).add(uid))
    request('search.take', { target: search.target, uid })
      .catch((e: unknown) => setError(takeError(e)))
      .finally(() => {
        if (!pendingRef.current.has(uid)) return
        const next = new Set(pendingRef.current)
        next.delete(uid)
        updatePending(next)
      })
  }

  const close = () => {
    if (search) void request('search.close', { target: search.target })
  }

  const row = { top: FOOTER_ROW.top, height: FOOTER_ROW.height }

  return (
    <div className="pointer-events-none fixed inset-0 text-white">
      <div className="pointer-events-auto absolute bg-black/60 backdrop-blur-md" style={SEARCH_PANEL}>
        <div
          className="absolute inset-x-0 bg-black/40"
          style={{ top: SEARCH_HEADER.top - SEARCH_PANEL.top, height: SEARCH_HEADER.height }}
        />
        <div
          className="absolute inset-x-0 bg-black/40"
          style={{ top: SEARCH_FOOTER.top - SEARCH_PANEL.top, height: SEARCH_FOOTER.height }}
        />
      </div>
      <div
        className="absolute flex items-center truncate text-lg font-bold uppercase tracking-wide"
        style={{ ...SEARCH_TITLE, top: SEARCH_HEADER.top, height: SEARCH_HEADER.height }}
      >
        {search ? search.title : 'Searching…'}
      </div>
      {search && (
        <div
          className="absolute flex items-center justify-end text-sm font-semibold text-white/80"
          style={{ ...SEARCH_COUNT, top: SEARCH_HEADER.top, height: SEARCH_HEADER.height }}
        >
          {search.items.length} items
        </div>
      )}
      {search && <BodyGrid items={search.items} pending={pending} onTake={take} />}
      {search && search.items.length === 0 && (
        <div
          className="pointer-events-none absolute grid place-items-center text-sm text-white/60"
          style={BODY_VIEWPORT}
        >
          Nothing left to take
        </div>
      )}
      {error && (
        <div className="absolute flex items-center truncate text-xs text-red-400" style={{ ...FOOTER_ERROR, ...row }}>
          {error}
        </div>
      )}
      <button
        type="button"
        className="pointer-events-auto absolute flex items-center justify-center rounded-sm bg-white/10 disabled:opacity-40"
        style={{ ...FOOTER_CLOSE, ...row }}
        disabled={!search}
        onClick={close}
      >
        <KeyHint k="Q" label="Close" />
      </button>
      <div className="absolute flex items-center justify-end" style={{ ...FOOTER_TAKE, ...row }}>
        <KeyHint k="LMB" label="Take" />
      </div>
    </div>
  )
}
