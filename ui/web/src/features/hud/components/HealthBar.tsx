export function HealthBar({
  health,
  maxHealth,
  away,
}: {
  health: number
  maxHealth: number
  away: boolean
}) {
  const ratio = away ? 0 : health / maxHealth
  return (
    <div className="flex h-1.5 gap-[2px]">
      {[0, 1, 2, 3].map((i) => (
        <div key={i} className="flex-1 bg-white/15 overflow-hidden">
          <div
            className={`h-full ${ratio < 0.3 ? 'bg-red-500' : 'bg-emerald-400'}`}
            style={{ width: `${Math.min(Math.max(ratio * 4 - i, 0), 1) * 100}%` }}
          />
        </div>
      ))}
    </div>
  )
}
