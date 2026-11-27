export type StageState = 'done' | 'current' | 'pending' | 'failed'

export interface Stage {
  label: string
  state: StageState
}

const STATE_WORD: Record<StageState, string> = {
  done: 'Done',
  current: 'In progress',
  pending: 'Pending',
  failed: 'Failed',
}

const CELL: Record<StageState, string> = {
  done: 'border-t-2 border-transparent text-zinc-300',
  current: 'border-t-2 border-amber-400 text-zinc-100',
  pending: 'border-t-2 border-transparent text-zinc-500',
  failed: 'border-t-2 border-red-400 text-zinc-100',
}

/** Fixed 448 x 40 row of boot stages; each cell shows its label and a readable state word. */
export function StageRail({ stages }: { stages: Stage[] }) {
  return (
    <ul role="list" className="flex h-10 w-[448px] gap-2">
      {stages.map((stage) => (
        <li
          key={stage.label}
          role="listitem"
          className={`flex h-10 w-[144px] flex-col justify-center px-2 text-xs leading-4 ${CELL[stage.state]}`}
        >
          <span className="font-semibold">{stage.label}</span>
          <span>
            {stage.state === 'done' && <span aria-hidden="true">✓ </span>}
            {STATE_WORD[stage.state]}
          </span>
        </li>
      ))}
    </ul>
  )
}
