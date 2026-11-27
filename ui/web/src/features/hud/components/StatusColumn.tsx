import type { HudState } from '@/lib/ipc/protocol'
import { formatClock } from '@/lib/format'
import { MINIMAP } from '../layout'

const PANEL = 'bg-zinc-950/60 rounded-md ring-1 ring-white/10'

function roleColor(role: string): string {
  switch (role) {
    case 'CITIZEN':
      return 'bg-zinc-500'
    case 'CRIMINAL':
      return 'bg-red-600'
    case 'COP':
      return 'bg-blue-600'
    default:
      return 'bg-zinc-700'
  }
}

export function StatusColumn({ hud }: { hud: HudState }) {
  return (
    <div
      className="absolute flex flex-col items-start gap-1.5"
      style={{ left: MINIMAP.left + MINIMAP.width + 12, top: MINIMAP.top }}
    >
      {hud.timer && hud.life !== 'DOWNED' && (
        <div className="bg-red-600 rounded px-2 py-0.5 text-sm font-bold">
          {hud.timer.label.toUpperCase()} {formatClock(hud.timer.seconds)}
        </div>
      )}
      <div className={`text-xs font-bold px-2 py-0.5 rounded ${roleColor(hud.role)}`}>
        {hud.role}
      </div>
      <div className={`${PANEL} text-xs px-2 py-0.5`}>NOTORIETY {hud.notoriety}</div>
    </div>
  )
}
