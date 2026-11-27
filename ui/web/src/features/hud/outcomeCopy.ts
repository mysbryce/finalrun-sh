import type { GameOverlayView, TransferView } from '@/lib/ipc/protocol'

const CAUSE: Record<GameOverlayView['cause'], string> = {
  bleed_out: 'You bled out.',
  finished: 'You were finished off.',
  other: 'You were killed.',
  surrender: 'You surrendered to the police.',
  cuffed: 'You were cuffed.',
}

const TRANSFER_SUMMARY: Record<TransferView['reason'], string> = {
  join: 'Entering the session.',
  travel: 'Map transfer.',
  extract: 'Extracted from LootyBay.',
  death: 'You died. Respawning at Motel.',
  arrest: 'Arrested. Returning as Citizen to Motel.',
}

const TRANSFER_ERROR: Record<NonNullable<TransferView['error']>, string> = {
  transfer_timeout: 'The server did not confirm the transfer in time.',
  map_load_failed: 'The map could not be loaded.',
  disconnected: 'Lost connection to the server.',
}

export function outcomeTitle(v: GameOverlayView): string {
  return v.kind === 'death' ? 'You died' : 'Arrested'
}

export function outcomeSummary(v: GameOverlayView): string[] {
  const lines = [CAUSE[v.cause]]
  if (v.kind === 'arrest' && v.bagForfeited && v.gearKept) lines.push('Bag forfeited · gear kept')
  return lines
}

export function outcomeStatus(v: GameOverlayView): string {
  return v.kind === 'death'
    ? `Respawning at ${v.destination}.`
    : `Returning as Citizen to ${v.destination}.`
}

export function transferTitle(t: TransferView): string {
  if (t.stage === 'failed') return 'Transfer failed'
  return t.reason === 'join' ? `Joining ${t.mapName}` : `Travelling to ${t.mapName}`
}

export function transferSummary(t: TransferView): string {
  return TRANSFER_SUMMARY[t.reason]
}

export function transferStatus(t: TransferView): string {
  if (t.stage === 'loading') return 'Loading map…'
  if (t.stage === 'waiting_for_spawn') return 'Waiting for the server…'
  return t.error ? TRANSFER_ERROR[t.error] : 'Transfer failed.'
}
