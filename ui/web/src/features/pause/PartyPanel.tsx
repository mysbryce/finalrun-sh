import { useState } from 'react'
import type { CSSProperties } from 'react'
import { request } from '@/lib/ipc/bridge'
import type { PartyPeer, PartyView } from '@/lib/ipc/protocol'
import { Button } from '@/lib/ui/Button'
import { Dropdown } from '@/lib/ui/Dropdown'
import { Modal } from '@/lib/ui/Modal'

/** Absolute box in base px, relative to the party panel (docs/ui-design/04-hud.md, Pause menu A10-A31). */
const box = (left: number, top: number, width: number, height: number): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width,
  height,
})

const MAX_MEMBERS = 3
const ROW_TOPS = [104, 156, 208]
const FILL = 'grid [&>button]:w-full'
// The Dropdown label stays for screen readers; the trigger fills the A23 box.
const PICKER = '[&>div]:w-full [&>div>span:first-child]:sr-only [&_button]:w-full'

type Confirm = { kind: 'kick'; peer: PartyPeer } | { kind: 'leave' } | null

export function PartyPanel({ party }: { party: PartyView }) {
  const [selected, setSelected] = useState('')
  const [confirm, setConfirm] = useState<Confirm>(null)
  const [error, setError] = useState<string | null>(null)

  const send = (method: string, params: Record<string, unknown> = {}) => {
    setError(null)
    setConfirm(null)
    void request(method, params).catch(() => setError('Party request failed.'))
  }

  const inParty = party.members.length > 0
  const pending = party.pending
  const target = party.players.some((p) => String(p.peerId) === selected) ? selected : ''
  const options =
    party.players.length === 0
      ? [{ value: '', label: 'No other players', disabled: true }]
      : party.players.map((p) => ({
          value: String(p.peerId),
          label: `${p.name} · ${p.peerId}`,
          disabled: !p.canInvite,
          reason: p.canInvite ? undefined : 'Party full',
        }))

  return (
    <div style={box(616, 112, 400, 528)} className="rounded-md bg-zinc-900 text-zinc-100">
      <h2 style={box(16, 16, 368, 28)} className="m-0 flex items-center text-lg leading-6 font-semibold">
        Party
      </h2>
      <p
        style={box(16, 52, 368, 40)}
        className="m-0 flex items-center gap-3 text-sm leading-5 text-zinc-300"
        aria-live="polite"
      >
        <span>{inParty ? `${party.members.length} of ${MAX_MEMBERS} members` : 'Not in a party'}</span>
        {pending !== null && <span className="text-amber-400">Pending: {pending}</span>}
      </p>

      {ROW_TOPS.map((top, i) => {
        const member = party.members[i]
        return (
          <div key={top} style={box(16, top, 368, 44)}>
            <div style={box(8, 4, 246, 36)} className="flex items-center gap-2 text-sm leading-5">
              {member ? (
                <>
                  <span className="truncate">{member.name}</span>
                  {member.leader && <span className="text-xs leading-4 text-amber-400">Leader</span>}
                  {member.isSelf && <span className="text-xs leading-4 text-zinc-300">You</span>}
                </>
              ) : (
                <span className="text-zinc-500">Empty slot</span>
              )}
            </div>
            {member?.canKick && (
              <div style={box(262, 4, 98, 36)} className={FILL}>
                <Button
                  label="Kick"
                  variant="secondary"
                  size="compact"
                  loading={pending === 'kick'}
                  onPress={() => {
                    setError(null)
                    setConfirm({ kind: 'kick', peer: member })
                  }}
                />
              </div>
            )}
          </div>
        )
      })}

      <div style={box(16, 264, 368, 36)} className={PICKER}>
        <Dropdown
          label="Invite player"
          value={target}
          options={options}
          onChange={setSelected}
          placeholder="Choose a player"
          disabled={party.players.length === 0}
        />
      </div>

      {party.incoming !== null && (
        <div style={box(16, 312, 368, 80)}>
          <p style={box(8, 6, 352, 24)} className="m-0 flex items-center text-sm leading-5">
            Invite from {party.incoming.name} · {party.incoming.expiresInSeconds} s
          </p>
          <div style={box(8, 36, 112, 36)} className={FILL}>
            <Button
              label="Accept"
              variant="primary"
              size="compact"
              disabled={!party.incoming.canAccept}
              loading={pending === 'accept'}
              onPress={() => send('party.accept', { inviterPeerId: party.incoming?.inviterPeerId })}
            />
          </div>
          <div style={box(128, 36, 112, 36)} className={FILL}>
            <Button
              label="Decline"
              variant="secondary"
              size="compact"
              loading={pending === 'decline'}
              onPress={() => send('party.decline', { inviterPeerId: party.incoming?.inviterPeerId })}
            />
          </div>
        </div>
      )}

      <div style={box(16, 408, 176, 40)} className={FILL}>
        {party.canCreate ? (
          <Button
            label="Create party"
            variant="secondary"
            loading={pending === 'create'}
            onPress={() => send('party.create')}
          />
        ) : (
          <Button
            label="Invite"
            variant="secondary"
            disabled={target === '' || !party.canInvite}
            loading={pending === 'invite'}
            onPress={() => send('party.invite', { targetPeerId: Number(target) })}
          />
        )}
      </div>
      {party.canLeave && (
        <div style={box(200, 408, 184, 40)} className={FILL}>
          <Button
            label="Leave party"
            variant="secondary"
            loading={pending === 'leave'}
            onPress={() => {
              setError(null)
              setConfirm({ kind: 'leave' })
            }}
          />
        </div>
      )}
      <div style={box(16, 456, 368, 48)} className="text-xs leading-4 text-red-400" aria-live="polite">
        {error !== null && (
          <p className="m-0" role="alert">
            {error}
          </p>
        )}
      </div>

      {confirm?.kind === 'kick' && (
        <Modal
          title={`Kick ${confirm.peer.name}?`}
          primary={{
            label: 'Kick',
            onPress: () => send('party.kick', { targetPeerId: confirm.peer.peerId }),
            busy: pending === 'kick',
          }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        />
      )}
      {confirm?.kind === 'leave' && (
        <Modal
          title="Leave the party?"
          primary={{ label: 'Leave', onPress: () => send('party.leave'), busy: pending === 'leave' }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        />
      )}
    </div>
  )
}
