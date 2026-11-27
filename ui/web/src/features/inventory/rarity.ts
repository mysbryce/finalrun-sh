export type Rarity = 'issued' | 'common' | 'rare' | 'epic'

export function rarityOf(value: number): Rarity {
  if (value <= 0) return 'issued'
  if (value < 250) return 'common'
  if (value < 600) return 'rare'
  return 'epic'
}

export const RARITY_TILE: Record<Rarity, string> = {
  issued: 'bg-gradient-to-b from-zinc-600/70 to-zinc-800/80',
  common: 'bg-gradient-to-b from-emerald-600/70 to-emerald-900/80',
  rare: 'bg-gradient-to-b from-violet-600/70 to-violet-900/80',
  epic: 'bg-gradient-to-b from-amber-500/70 to-amber-800/80',
}
