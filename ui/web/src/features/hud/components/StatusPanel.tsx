import type { HudState } from '@/lib/ipc/protocol'

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

function lifeColor(life: string): string {
  switch (life) {
    case 'DOWNED':
      return 'text-amber-400'
    case 'DEAD':
      return 'text-red-400'
    default:
      return 'text-emerald-400'
  }
}

export function StatusPanel({ hud }: { hud: HudState }) {
  return (
    <div className="absolute left-4 top-4 rounded-xl bg-black/55 px-4 py-3 text-white">
      <div className="flex items-center gap-2">
        <span className={`rounded px-2 py-0.5 text-xs font-bold ${roleColor(hud.role)}`}>
          {hud.role}
        </span>
        <span className={`text-sm font-semibold ${lifeColor(hud.life)}`}>{hud.life}</span>
      </div>
      <div className="mt-1 text-sm">
        Cash ${hud.cash.toLocaleString('en-US')} · Bag ${hud.bag.toLocaleString('en-US')} ·
        Notoriety {hud.notoriety.toLocaleString('en-US')}
      </div>
    </div>
  )
}
