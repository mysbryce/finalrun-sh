import { Panel } from '@/lib/ui/Panel'
import { ProgressBar } from '@/lib/ui/ProgressBar'
import { BLEED_OUT, BLEED_OUT_SECONDS, DOWNED_CONTROLS, DOWNED_PANEL, DOWNED_TITLE } from '../layout'

const ROW = 'absolute left-1/2 -translate-x-1/2'

/** Downed panel: title with the bleed-out seconds, bleed-out bar and the controls line. */
export function DownedPanel({ seconds }: { seconds: number | null }) {
  return (
    <>
      <Panel inset={0} className="absolute" style={{ ...DOWNED_PANEL }} />
      <div role="status" className={`${ROW} flex items-center text-lg leading-7 font-semibold`} style={{ ...DOWNED_TITLE }}>
        Downed
        <span aria-hidden="true">
          {' · '}
          <span className="tabular">{seconds === null ? '—' : `${Math.ceil(seconds)} s`}</span>
        </span>
      </div>
      <div className={ROW} style={{ ...BLEED_OUT }}>
        <ProgressBar label="Bleed-out" value={seconds ?? undefined} max={BLEED_OUT_SECONDS} />
      </div>
      <div className={`${ROW} flex items-center text-xs leading-4 text-zinc-300`} style={{ ...DOWNED_CONTROLS }}>
        Crawl to cover · wait for a revive
      </div>
    </>
  )
}
