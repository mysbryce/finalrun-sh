import type { PartyMember } from '@/lib/ipc/protocol'
import { HealthBar } from './HealthBar'

const PANEL = 'bg-zinc-950/60 rounded-md ring-1 ring-white/10'

export function PartyPanel({
  party,
  self,
  health,
  maxHealth,
}: {
  party: PartyMember[]
  self: { name: string }
  health: number
  maxHealth: number
}) {
  return (
    <div className="absolute left-6 bottom-6 flex w-[280px] flex-col gap-2">
      {party.map((member, index) => (
        <div key={index} className={`${PANEL} px-3 py-1.5`}>
          <div className="flex items-center gap-2">
            <span
              className={`h-2 w-2 rounded-full ${member.leader ? 'bg-amber-400' : 'bg-sky-400'}`}
            />
            <span className="text-sm font-semibold">{member.name}</span>
            {member.away && <span className="text-[10px] text-white/50">AWAY</span>}
          </div>
          <HealthBar health={member.health} maxHealth={member.maxHealth} away={member.away} />
        </div>
      ))}
      <div className={`${PANEL} px-3 py-2`}>
        <div className="flex items-center gap-2">
          <span className="h-2 w-2 rounded-full bg-emerald-400" />
          <span className="text-sm font-semibold">{self.name}</span>
        </div>
        <HealthBar health={health} maxHealth={maxHealth} away={false} />
      </div>
    </div>
  )
}
