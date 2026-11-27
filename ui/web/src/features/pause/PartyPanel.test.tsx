import { fireEvent, render, screen, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import type { PartyView } from '@/lib/ipc/protocol'
import { PartyPanel } from './PartyPanel'
import { PauseScreen } from './PauseScreen'
import { usePartyStore } from './partyStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

const NO_PARTY: PartyView = {
  members: [],
  players: [{ peerId: 7, name: 'Player 7', canInvite: true }],
  incoming: null,
  canCreate: true,
  canInvite: true,
  canLeave: false,
  pending: null,
  issue: null,
}

const LEADER: PartyView = {
  members: [
    { peerId: 2, name: 'Player 2', leader: true, isSelf: true, presence: 'in_session', canKick: false },
    { peerId: 5, name: 'Player 5', leader: false, isSelf: false, presence: 'in_session', canKick: true },
  ],
  players: [
    { peerId: 7, name: 'Player 7', canInvite: true },
    { peerId: 9, name: 'Player 9', canInvite: true },
  ],
  incoming: null,
  canCreate: false,
  canInvite: true,
  canLeave: true,
  pending: null,
  issue: null,
}

describe('PartyPanel', () => {
  beforeEach(() => {
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => Promise.resolve({}))
    usePartyStore.getState().setParty(null)
  })

  it('Create party sends party.create when not in a party', () => {
    render(<PartyPanel party={NO_PARTY} />)
    expect(screen.getByText('Not in a party')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Create party' }))
    expect(request).toHaveBeenCalledWith('party.create', {})
  })

  it('selecting a player and Invite sends party.invite with that peer id', () => {
    render(<PartyPanel party={LEADER} />)
    expect(screen.getByRole('button', { name: 'Invite' })).toBeDisabled()
    fireEvent.click(screen.getByRole('button', { name: /Invite player/ }))
    fireEvent.click(screen.getByRole('option', { name: 'Player 9' }))
    fireEvent.click(screen.getByRole('button', { name: 'Invite' }))
    expect(request).toHaveBeenCalledWith('party.invite', { targetPeerId: 9 })
  })

  it('Kick asks for confirmation, then sends party.kick', () => {
    render(<PartyPanel party={LEADER} />)
    expect(screen.getAllByRole('button', { name: 'Kick' })).toHaveLength(1)
    fireEvent.click(screen.getByRole('button', { name: 'Kick' }))
    const dialog = screen.getByRole('dialog', { name: 'Kick Player 5?' })
    expect(within(dialog).getByRole('button', { name: 'Cancel' })).toHaveFocus()
    expect(request).not.toHaveBeenCalled()
    fireEvent.click(within(dialog).getByRole('button', { name: 'Kick' }))
    expect(request).toHaveBeenCalledWith('party.kick', { targetPeerId: 5 })
  })

  it('Accept and Decline send their methods with inviterPeerId', () => {
    const view: PartyView = {
      ...NO_PARTY,
      incoming: { inviterPeerId: 11, name: 'Player 11', expiresInSeconds: 18, canAccept: true },
    }
    render(<PartyPanel party={view} />)
    expect(screen.getByText('Invite from Player 11 · 18 s')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Accept' }))
    expect(request).toHaveBeenCalledWith('party.accept', { inviterPeerId: 11 })
    fireEvent.click(screen.getByRole('button', { name: 'Decline' }))
    expect(request).toHaveBeenCalledWith('party.decline', { inviterPeerId: 11 })
  })

  it('PauseScreen renders no party panel while party is null', () => {
    render(<PauseScreen />)
    expect(screen.queryByRole('heading', { name: 'Party' })).toBeNull()
  })

  it('PauseScreen renders the party panel when party is set', () => {
    usePartyStore.getState().setParty(LEADER)
    render(<PauseScreen />)
    expect(screen.getByRole('heading', { name: 'Party' })).toBeInTheDocument()
    expect(screen.getByText('2 of 3 members')).toBeInTheDocument()
    expect(screen.getByText('Empty slot')).toBeInTheDocument()
  })

  it('Party full disables the picker options', () => {
    const view: PartyView = {
      ...LEADER,
      canInvite: false,
      players: [{ peerId: 7, name: 'Player 7', canInvite: false }],
    }
    render(<PartyPanel party={view} />)
    expect(screen.getByRole('button', { name: 'Invite' })).toBeDisabled()
    fireEvent.click(screen.getByRole('button', { name: /Invite player/ }))
    const option = screen.getByRole('option', { name: /Player 7/ })
    expect(option).toHaveAttribute('aria-disabled', 'true')
    expect(within(option).getByText('Party full')).toBeInTheDocument()
  })

  it('pending shows the verb and loading on that action', () => {
    render(<PartyPanel party={{ ...NO_PARTY, pending: 'create' }} />)
    expect(screen.getByText('Pending: create')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Create party' })).toHaveAttribute('aria-busy', 'true')
  })
})
