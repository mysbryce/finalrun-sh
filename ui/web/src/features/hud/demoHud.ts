import type { HudState } from '@/lib/ipc/protocol'

export const DEMO_HUD: HudState = {
  role: 'CRIMINAL',
  life: 'ALIVE',
  health: 75,
  maxHealth: 100,
  cash: 50,
  bag: 500,
  notoriety: 500,
  heading: 312,
  timer: { label: 'Masking', seconds: 2 },
  interact: {
    title: 'Loot crate',
    actions: [
      { key: 'E', label: 'lockpick' },
      { key: 'V', label: 'smash' },
    ],
  },
  notifications: ['Looted $300 (silent)'],
  self: { name: 'Player 2' },
  party: [
    {
      name: 'Player 3',
      health: 100,
      maxHealth: 100,
      life: 'ALIVE',
      leader: true,
      away: false,
    },
    { name: 'Player 4', health: -1, maxHealth: 100, life: '?', leader: false, away: true },
  ],
  hotbar: [{ label: 'Pistol' }, null, null, null, null, null],
  activeSlot: 0,
  net: { fps: 60, ping: 40 },
}
