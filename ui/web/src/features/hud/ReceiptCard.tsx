import { Panel } from '@/lib/ui/Panel'
import { useOverlayStore } from './overlayStore'
import { outcomeSummary, outcomeTitle } from './outcomeCopy'
import { RECEIPT_CARD, RECEIPT_HINT, RECEIPT_SUMMARY, RECEIPT_TITLE } from './layout'

const ROW = 'absolute left-1/2 -translate-x-1/2'

/** Compact outcome receipt over the new HUD (`/`). Godot handles the dismissal. */
export function ReceiptCard() {
  const overlay = useOverlayStore((s) => s.overlay)
  if (!overlay) return null

  return (
    <div className="pointer-events-none fixed inset-0 text-zinc-100">
      <Panel inset={0} className="absolute" style={{ ...RECEIPT_CARD }} />
      <div className={`${ROW} flex items-center text-lg leading-7 font-semibold`} style={{ ...RECEIPT_TITLE }}>
        {outcomeTitle(overlay)}
      </div>
      <div className={`${ROW} flex flex-col justify-center text-sm leading-5`} style={{ ...RECEIPT_SUMMARY }}>
        {outcomeSummary(overlay).map((line) => (
          <span key={line}>{line}</span>
        ))}
      </div>
      <div className={`${ROW} flex items-center text-xs leading-4 text-zinc-300`} style={{ ...RECEIPT_HINT }}>
        Esc or click to dismiss
      </div>
    </div>
  )
}
