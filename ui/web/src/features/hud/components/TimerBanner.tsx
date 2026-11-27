import type { HudTimer } from '@/lib/ipc/protocol'

export function TimerBanner({ timer }: { timer: HudTimer }) {
  return (
    <div
      className={`absolute left-1/2 top-4 -translate-x-1/2 rounded-lg px-4 py-2 text-white ${
        timer.label === 'Bleeding out' ? 'bg-amber-600' : 'bg-red-600'
      }`}
    >
      <span className="text-2xl font-bold">
        {timer.label}: {timer.seconds} s
      </span>
    </div>
  )
}
