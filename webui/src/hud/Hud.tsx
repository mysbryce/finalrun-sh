import { useHudStore } from '../store'

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

export function Hud() {
  const hud = useHudStore((s) => s.hud)
  if (!hud) return null

  return (
    <div className="pointer-events-none fixed inset-0">
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

      {hud.timer !== null && (
        <div
          className={`absolute left-1/2 top-4 -translate-x-1/2 rounded-lg px-4 py-2 text-white ${
            hud.timer.label === 'Bleeding out' ? 'bg-amber-600' : 'bg-red-600'
          }`}
        >
          <span className="text-2xl font-bold">
            {hud.timer.label}: {hud.timer.seconds} s
          </span>
        </div>
      )}

      <div className="absolute right-4 top-4 flex flex-col items-end gap-1">
        {hud.notifications.map((notification, index) => (
          <div
            key={index}
            className="rounded-lg bg-black/60 px-3 py-1 text-sm text-white"
          >
            {notification}
          </div>
        ))}
      </div>

      {hud.prompt !== '' && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 rounded-full bg-black/60 px-4 py-1 text-white">
          {hud.prompt}
        </div>
      )}
    </div>
  )
}
