import { SAFETY } from '../layout'

export function SafetyLine() {
  return (
    <div
      className="absolute flex items-center gap-2 rounded bg-zinc-950/60 px-2 text-xs font-bold ring-1 ring-emerald-400/70"
      style={{ left: SAFETY.left, top: SAFETY.top, width: SAFETY.width, height: SAFETY.height }}
    >
      <span className="h-2 w-2 rounded-sm bg-emerald-400" aria-hidden="true" />
      SAFE ZONE - weapons locked
    </div>
  )
}
