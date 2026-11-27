import { describe, expect, it } from 'vitest'
import type { GameOverlayView, TransferView } from '@/lib/ipc/protocol'
import {
  outcomeStatus,
  outcomeSummary,
  outcomeTitle,
  transferStatus,
  transferSummary,
  transferTitle,
} from './outcomeCopy'

function death(cause: 'bleed_out' | 'finished' | 'other'): GameOverlayView {
  return { receiptId: 'r', remainingMs: 1000, kind: 'death', cause, destination: 'Motel' }
}

function arrest(cause: 'surrender' | 'cuffed'): GameOverlayView {
  return {
    receiptId: 'r',
    remainingMs: 1000,
    kind: 'arrest',
    cause,
    destination: 'Motel',
    bagForfeited: true,
    gearKept: true,
  }
}

const BASE: TransferView = {
  mapName: 'Motel',
  instanceId: null,
  stage: 'loading',
  reason: 'join',
  progress: null,
  error: null,
}

describe('outcomeCopy', () => {
  it('titles death and arrest', () => {
    expect(outcomeTitle(death('other'))).toBe('You died')
    expect(outcomeTitle(arrest('cuffed'))).toBe('Arrested')
  })

  it('summarises every cause', () => {
    expect(outcomeSummary(death('bleed_out'))).toEqual(['You bled out.'])
    expect(outcomeSummary(death('finished'))).toEqual(['You were finished off.'])
    expect(outcomeSummary(death('other'))).toEqual(['You were killed.'])
    expect(outcomeSummary(arrest('surrender'))).toEqual(['You surrendered to the police.', 'Bag forfeited · gear kept'])
    expect(outcomeSummary(arrest('cuffed'))).toEqual(['You were cuffed.', 'Bag forfeited · gear kept'])
  })

  it('states the destination', () => {
    expect(outcomeStatus(death('bleed_out'))).toBe('Respawning at Motel.')
    expect(outcomeStatus(arrest('surrender'))).toBe('Returning as Citizen to Motel.')
  })

  it('titles transfers', () => {
    expect(transferTitle(BASE)).toBe('Joining Motel')
    expect(transferTitle({ ...BASE, reason: 'travel', mapName: 'LootyBay' })).toBe('Travelling to LootyBay')
    expect(transferTitle({ ...BASE, stage: 'failed', error: 'disconnected' })).toBe('Transfer failed')
  })

  it('summarises every transfer reason', () => {
    expect(transferSummary(BASE)).toBe('Entering the session.')
    expect(transferSummary({ ...BASE, reason: 'travel' })).toBe('Map transfer.')
    expect(transferSummary({ ...BASE, reason: 'extract' })).toBe('Extracted from LootyBay.')
    expect(transferSummary({ ...BASE, reason: 'death' })).toBe('You died. Respawning at Motel.')
    expect(transferSummary({ ...BASE, reason: 'arrest' })).toBe('Arrested. Returning as Citizen to Motel.')
  })

  it('states every transfer stage and error', () => {
    expect(transferStatus(BASE)).toBe('Loading map…')
    expect(transferStatus({ ...BASE, stage: 'waiting_for_spawn' })).toBe('Waiting for the server…')
    const failed: TransferView = { ...BASE, stage: 'failed' }
    expect(transferStatus({ ...failed, error: 'transfer_timeout' })).toBe(
      'The server did not confirm the transfer in time.',
    )
    expect(transferStatus({ ...failed, error: 'map_load_failed' })).toBe('The map could not be loaded.')
    expect(transferStatus({ ...failed, error: 'disconnected' })).toBe('Lost connection to the server.')
    expect(transferStatus({ ...failed, error: null })).toBe('Transfer failed.')
  })
})
