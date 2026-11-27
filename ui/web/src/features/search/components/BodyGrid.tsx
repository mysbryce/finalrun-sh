import { useState } from 'react'
import type { SearchItem } from '@/lib/ipc/protocol'
import { BAG_COLUMNS, BAG_ROWS, GAP, PITCH, cellBox } from '@/lib/grid/gridLayout'
import { packRows } from '@/lib/grid/placement'
import { ItemTile } from '@/lib/grid/ItemTile'
import { BODY_SCROLLBAR, BODY_VIEWPORT, THUMB_MIN } from '../layout'

type Props = {
  items: SearchItem[]
  pending: ReadonlySet<number>
  onTake: (uid: number) => void
}

export function BodyGrid({ items, pending, onTake }: Props) {
  const [scrollTop, setScrollTop] = useState(0)
  const { packed, rows } = packRows(items, BAG_COLUMNS, BAG_ROWS)
  const contentHeight = rows * PITCH - GAP
  const view = BODY_VIEWPORT.height
  const thumbH = Math.max(THUMB_MIN, (view * view) / contentHeight)
  const maxScroll = contentHeight - view
  const thumbTop = BODY_SCROLLBAR.top + (maxScroll > 0 ? (Math.min(scrollTop, maxScroll) * (view - thumbH)) / maxScroll : 0)
  return (
    <>
      <div
        className="pointer-events-auto absolute overflow-y-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        style={BODY_VIEWPORT}
        onScroll={(e) => setScrollTop(e.currentTarget.scrollTop)}
      >
        <div data-testid="body-content" className="relative" style={{ width: BODY_VIEWPORT.width, height: contentHeight }}>
          {Array.from({ length: rows * BAG_COLUMNS }, (_, i) => {
            const box = cellBox(i)
            return (
              <div key={`cell-${i}`} className="absolute" style={box}>
                <ItemTile size={{ w: box.width, h: box.height }} />
              </div>
            )
          })}
          {packed.map(({ item, slot }) => {
            const box = cellBox(slot, item.w, item.h)
            const busy = pending.has(item.uid)
            return (
              <div
                key={item.uid}
                className={`absolute ${busy ? 'cursor-wait opacity-50' : ''}`}
                style={box}
                aria-busy={busy ? 'true' : undefined}
                onFocus={(e) => (e.target as HTMLElement).scrollIntoView?.({ block: 'nearest' })}
              >
                <ItemTile item={item} size={{ w: box.width, h: box.height }} onSelect={busy ? undefined : onTake} />
              </div>
            )
          })}
        </div>
      </div>
      {contentHeight > view && (
        <div className="absolute bg-white/10" style={BODY_SCROLLBAR}>
          <div
            className="absolute inset-x-0 bg-white/60"
            style={{ top: thumbTop - BODY_SCROLLBAR.top, height: thumbH }}
          />
        </div>
      )}
    </>
  )
}
