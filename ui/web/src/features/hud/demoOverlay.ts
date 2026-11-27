import type { GameOverlayView, TransferView } from '@/lib/ipc/protocol'

export const DEMO_RECEIPT_DEATH: GameOverlayView = {
  receiptId: 'demo-death',
  remainingMs: 6000,
  kind: 'death',
  cause: 'bleed_out',
  destination: 'Motel',
}

export const DEMO_RECEIPT_ARREST: GameOverlayView = {
  receiptId: 'demo-arrest',
  remainingMs: 6000,
  kind: 'arrest',
  cause: 'surrender',
  destination: 'Motel',
  bagForfeited: true,
  gearKept: true,
}

export const DEMO_TRANSFER: TransferView = {
  mapName: 'Motel',
  instanceId: null,
  stage: 'loading',
  reason: 'join',
  progress: null,
  error: null,
}

export const DEMO_TRANSFER_FAILED: TransferView = {
  ...DEMO_TRANSFER,
  stage: 'failed',
  error: 'transfer_timeout',
}
