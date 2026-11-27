import type { DownedChannels as DownedChannelsView } from '@/lib/ipc/protocol'
import { ProgressBar } from '@/lib/ui/ProgressBar'
import { FINISH_WARNING, REVIVE_PROGRESS } from '../layout'

const ROW = 'absolute left-1/2 flex -translate-x-1/2 items-center gap-2 rounded-md px-3 text-sm font-bold'

function Triangle({ className }: { className: string }) {
  return (
    <svg width={14} height={14} viewBox="0 0 14 14" className={`shrink-0 ${className}`} aria-hidden="true">
      <polygon points="7,1 13,13 1,13" />
    </svg>
  )
}

function warning(channels: DownedChannelsView | null | undefined) {
  // Old snapshot without channel data: show a dash and wait for the next one.
  if (!channels) return <span>—</span>
  if (channels.finish) {
    return (
      <>
        <Triangle className="fill-red-400" />
        <span className="text-red-200">Finish in progress</span>
      </>
    )
  }
  return (
    <>
      <Triangle className="fill-none stroke-white/70" />
      <span className="text-white/80">At risk of being finished</span>
    </>
  )
}

export function DownedChannels({ channels }: { channels: DownedChannelsView | null | undefined }) {
  const revive = channels?.revive
  const finishing = Boolean(channels?.finish)
  return (
    <>
      {revive && (
        <div
          className={`${ROW} bg-zinc-950/70`}
          style={{ top: REVIVE_PROGRESS.top, width: REVIVE_PROGRESS.width, height: REVIVE_PROGRESS.height }}
        >
          <span className="shrink-0">Being revived</span>
          <div className="flex-1">
            <ProgressBar
              label="Revive progress"
              value={revive.durationSeconds - revive.secondsLeft}
              max={revive.durationSeconds}
            />
          </div>
          <span className="tabular shrink-0">{Math.ceil(revive.secondsLeft)} s</span>
        </div>
      )}
      <div
        role="status"
        aria-live="polite"
        className={`${ROW} ${finishing ? 'bg-red-950/80 ring-2 ring-red-500' : 'bg-zinc-950/70 ring-1 ring-white/20'}`}
        style={{ top: FINISH_WARNING.top, width: FINISH_WARNING.width, height: FINISH_WARNING.height }}
      >
        {warning(channels)}
      </div>
    </>
  )
}
