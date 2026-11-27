import type { HeistAlertView } from '@/lib/ipc/protocol'
import { HEIST_ALERT } from '../layout'

export function heistText(alert: HeistAlertView): string {
  return alert.location ? `${alert.label} · ${alert.location}` : alert.label
}

export function HeistAlert({ alert }: { alert: HeistAlertView }) {
  return (
    <div
      role="status"
      aria-live="polite"
      className="absolute left-1/2 flex -translate-x-1/2 items-center gap-2 rounded-md border-l-4 border-amber-400 bg-zinc-950/70 px-3 text-sm font-bold"
      style={{ top: HEIST_ALERT.top, width: HEIST_ALERT.width, height: HEIST_ALERT.height }}
    >
      <svg width={14} height={14} viewBox="0 0 14 14" className="shrink-0 fill-amber-400" aria-hidden="true">
        <polygon points="7,1 13,13 1,13" />
      </svg>
      <span className="truncate">{heistText(alert)}</span>
    </div>
  )
}
