import { useState } from 'react'
import type { CSSProperties } from 'react'
import { request } from '@/lib/ipc/bridge'
import { Button } from '@/lib/ui/Button'
import { Modal } from '@/lib/ui/Modal'
import { Panel } from '@/lib/ui/Panel'
import { PartyPanel } from './PartyPanel'
import { usePartyStore } from './partyStore'

/** Absolute box in base px, relative to the pause panel (docs/ui-design/04-hud.md, Pause menu A02-A09). */
const box = (left: number, top: number, width: number, height: number): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width,
  height,
})

const ROW = 'grid [&>button]:w-full'

type Confirm = 'leave' | 'quit' | null

export function PauseScreen() {
  const [confirm, setConfirm] = useState<Confirm>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const party = usePartyStore((s) => s.party)

  const send = (method: string, failText: string) => {
    setError(null)
    setBusy(true)
    void request(method)
      .then(() => setBusy(false))
      .catch(() => {
        setBusy(false)
        setConfirm(null)
        setError(failText)
      })
  }

  const open = (which: Confirm) => {
    setError(null)
    setConfirm(which)
  }

  return (
    <div className="pointer-events-auto fixed inset-0 bg-zinc-950/55 text-zinc-100">
      <Panel title="Paused" inset={0} style={box(232, 160, 360, 400)}>
        <h2 style={box(24, 24, 312, 36)} className="m-0 flex items-center text-lg leading-6 font-semibold">
          Paused
        </h2>
        <p style={box(24, 68, 312, 40)} className="m-0 flex items-center text-sm leading-5 text-zinc-300">
          Session continues
        </p>
        <div style={box(24, 120, 312, 40)} className={ROW}>
          <Button label="Resume" variant="primary" onPress={() => send('pause.resume', 'Could not resume.')} />
        </div>
        <div style={box(24, 172, 312, 40)} className={ROW}>
          <Button label="Settings" variant="secondary" onPress={() => send('settings.open', 'Could not open settings.')} />
        </div>
        <div style={box(24, 224, 312, 40)} className={ROW}>
          <Button label="Leave to Lobby" variant="secondary" onPress={() => open('leave')} />
        </div>
        <div style={box(24, 276, 312, 40)} className={ROW}>
          <Button label="Quit" variant="secondary" onPress={() => open('quit')} />
        </div>
        <div style={box(24, 328, 312, 48)} className="text-xs leading-4 text-red-400" aria-live="polite">
          {error !== null && (
            <p className="m-0" role="alert">
              {error}
            </p>
          )}
        </div>
      </Panel>
      {party !== null && <PartyPanel party={party} />}

      {confirm === 'leave' && (
        <Modal
          title="Leave to lobby?"
          primary={{ label: 'Leave', onPress: () => send('session.leave', 'Could not leave the session.'), busy }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        >
          You will disconnect from this server. Your character stays where the server puts it.
        </Modal>
      )}
      {confirm === 'quit' && (
        <Modal
          title="Quit FinalRun?"
          primary={{ label: 'Quit', onPress: () => send('app.quit', 'Could not quit.'), busy }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        />
      )}
    </div>
  )
}
