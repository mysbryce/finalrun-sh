import type { LobbyView } from '@/lib/ipc/protocol'

export const DEMO_LOBBY: LobbyView = {
  playerName: null,
  connection: { status: 'disconnected', serverId: null, pingMs: null, error: 'disconnected' },
  capabilities: { joinById: false, quickJoin: false, partyStaging: false },
  canPlay: true,
  party: null,
  appearance: { status: 'placeholder', bodyType: null, slots: {} },
  news: {
    status: 'ready',
    entries: [
      {
        version: '0.2.0',
        publishedOn: '2026-11-27',
        title: 'New boot, lobby and character',
        summary:
          'Splash screen with retry, a lobby after disconnects, and the first CC0 base character with walk, sprint and downed poses.',
      },
      {
        version: '0.1.0',
        publishedOn: '2026-10-15',
        title: 'First playable',
        summary: 'Motel, LootyBay, House and Center maps with looting, cops, masks and parties.',
      },
    ],
  },
}
