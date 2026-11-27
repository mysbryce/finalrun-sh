import { useEffect, useRef, useState } from 'react'
import { request } from '@/lib/ipc/bridge'
import { Button } from '@/lib/ui/Button'
import { Panel } from '@/lib/ui/Panel'
import { ProgressBar } from '@/lib/ui/ProgressBar'
import { StageRail } from '@/lib/ui/StageRail'
import type { Stage } from '@/lib/ui/StageRail'
import type { TransferView } from '@/lib/ipc/protocol'
import { useOverlayStore } from './overlayStore'
import { transferStatus, transferSummary, transferTitle } from './outcomeCopy'
import {
  OVERLAY_FOOTER,
  OVERLAY_PANEL,
  OVERLAY_PROGRESS,
  OVERLAY_STATUS,
  OVERLAY_SUMMARY,
  OVERLAY_TITLE,
} from './layout'

const ROW = 'absolute left-1/2 -translate-x-1/2'

function stages(stage: TransferView['stage']): Stage[] {
  return stage === 'waiting_for_spawn'
    ? [
        { label: 'Load map', state: 'done' },
        { label: 'Spawn', state: 'current' },
      ]
    : [
        { label: 'Load map', state: 'current' },
        { label: 'Spawn', state: 'pending' },
      ]
}

/** Map transfer screen (`/transfer`). The receipt card is not drawn here; the summary carries the outcome. */
export function TransferScreen() {
  const transfer = useOverlayStore((s) => s.transfer)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState(false)
  const buttonWrap = useRef<HTMLDivElement>(null)
  const failed = transfer?.stage === 'failed'

  useEffect(() => {
    setError(false)
    setPending(false)
  }, [transfer])

  useEffect(() => {
    if (failed && !pending) buttonWrap.current?.querySelector('button')?.focus()
  }, [failed, pending])

  if (!transfer) return null

  const returnToLobby = () => {
    setPending(true)
    setError(false)
    // On success Godot routes away, so the button stays in loading.
    request('transfer.return_to_lobby', {}).catch(() => {
      setPending(false)
      setError(true)
    })
  }

  return (
    <div className="fixed inset-0 text-zinc-100">
      <div className="fixed inset-0 bg-zinc-950/55" />
      <Panel inset={0} className="absolute" style={{ ...OVERLAY_PANEL }} />
      <div className={`${ROW} flex items-center text-2xl leading-8 font-semibold`} style={{ ...OVERLAY_TITLE }}>
        {transferTitle(transfer)}
      </div>
      <div className={`${ROW} flex items-center text-sm leading-5`} style={{ ...OVERLAY_SUMMARY }}>
        {transferSummary(transfer)}
      </div>
      <div
        role={failed ? 'alert' : 'status'}
        className={`${ROW} flex items-center text-sm leading-5 ${failed ? 'text-red-200' : 'text-zinc-300'}`}
        style={{ ...OVERLAY_STATUS }}
      >
        {error ? 'Could not return to the lobby.' : transferStatus(transfer)}
      </div>
      {!failed && typeof transfer.progress === 'number' && (
        <div className={ROW} style={{ ...OVERLAY_PROGRESS }}>
          <ProgressBar label="Map loading" value={transfer.progress} max={1} />
        </div>
      )}
      <div ref={buttonWrap} className={`${ROW} flex items-center justify-end`} style={{ ...OVERLAY_FOOTER }}>
        {failed ? (
          <Button label="Return to Lobby" variant="primary" loading={pending} onPress={returnToLobby} />
        ) : (
          <StageRail stages={stages(transfer.stage)} />
        )}
      </div>
    </div>
  )
}
