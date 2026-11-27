import type { HudInteract } from '@/lib/ipc/protocol'

export function InteractCard({ interact }: { interact: HudInteract }) {
  return (
    <div className="absolute left-1/2 top-[58%] -translate-x-1/2 flex flex-col items-start gap-1">
      {interact.title !== '' && (
        <div className="bg-zinc-950/70 px-3 py-1 text-lg font-bold uppercase tracking-wider">
          {interact.title}
        </div>
      )}
      {interact.actions.map((action, index) => (
        <div key={index} className="flex items-center gap-2">
          {action.key !== '' && (
            <span className="grid h-6 w-6 place-items-center rounded-sm bg-white text-xs font-bold text-zinc-900">
              {action.key}
            </span>
          )}
          <span className="rounded-sm bg-zinc-950/60 px-3 py-1 text-sm capitalize ring-1 ring-amber-400/80">
            {action.label}
          </span>
        </div>
      ))}
    </div>
  )
}
