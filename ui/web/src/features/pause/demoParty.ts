import type { PartyView } from '@/lib/ipc/protocol'

/** Dev preview (`#pause`): leader self + 1 member, 2 roster players, an incoming invite. */
export const DEMO_PARTY: PartyView = {
  members: [
    { peerId: 2, name: 'Player 2', leader: true, isSelf: true, presence: 'in_session', canKick: false },
    { peerId: 5, name: 'Player 5', leader: false, isSelf: false, presence: 'in_session', canKick: true },
  ],
  players: [
    { peerId: 7, name: 'Player 7', canInvite: true },
    { peerId: 9, name: 'Player 9', canInvite: true },
  ],
  incoming: { inviterPeerId: 11, name: 'Player 11', expiresInSeconds: 18, canAccept: false },
  canCreate: false,
  canInvite: true,
  canLeave: true,
  pending: null,
  issue: null,
}
