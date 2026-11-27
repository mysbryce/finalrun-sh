import type { MouseEvent } from 'react'
import { request } from '@/lib/ipc/bridge'
import { Button } from '@/lib/ui/Button'
import { KeyHint } from '@/lib/ui/KeyHint'
import { Panel } from '@/lib/ui/Panel'
import { useOverlayStore } from './overlayStore'
import { outcomeStatus, outcomeSummary, outcomeTitle } from './outcomeCopy'
import { OVERLAY_FOOTER, OVERLAY_PANEL, OVERLAY_STATUS, OVERLAY_SUMMARY, OVERLAY_TITLE } from './layout'

const ROW = 'absolute left-1/2 -translate-x-1/2'

function stop(e: MouseEvent) {
  e.stopPropagation()
}

/** Death / arrest receipt over the dimmed world (`/death`, `/arrest`). */
export function ReceiptScreen() {
  const overlay = useOverlayStore((s) => s.overlay)
  if (!overlay) return null

  const dismiss = () => {
    // An expired id is a no-op on the host, so errors are ignored.
    request('overlay.dismiss', { receiptId: overlay.receiptId }).catch(() => {})
  }

  return (
    <div className="fixed inset-0 text-zinc-100">
      <div data-testid="overlay-dim" className="fixed inset-0 bg-zinc-950/55" onClick={dismiss} />
      <div onClick={stop}>
        <Panel inset={0} className="absolute" style={{ ...OVERLAY_PANEL }} />
      </div>
      <div
        role="status"
        onClick={stop}
        className={`${ROW} flex items-center text-2xl leading-8 font-semibold`}
        style={{ ...OVERLAY_TITLE }}
      >
        {outcomeTitle(overlay)}
      </div>
      <div onClick={stop} className={`${ROW} flex flex-col justify-center text-sm leading-5`} style={{ ...OVERLAY_SUMMARY }}>
        {outcomeSummary(overlay).map((line) => (
          <span key={line}>{line}</span>
        ))}
      </div>
      <div onClick={stop} className={`${ROW} flex items-center text-sm leading-5 text-zinc-300`} style={{ ...OVERLAY_STATUS }}>
        {outcomeStatus(overlay)}
      </div>
      <div onClick={stop} className={`${ROW} flex items-center justify-end gap-4`} style={{ ...OVERLAY_FOOTER }}>
        <KeyHint k="Esc" label="Dismiss" />
        <Button label="Dismiss" variant="primary" onPress={dismiss} />
      </div>
    </div>
  )
}
