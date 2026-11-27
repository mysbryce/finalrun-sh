export type Rarity = 'issued' | 'common' | 'rare' | 'epic'

export function rarityOf(value: number): Rarity {
  if (value <= 0) return 'issued'
  if (value < 250) return 'common'
  if (value < 600) return 'rare'
  return 'epic'
}

export const RARITY_TILE: Record<Rarity, string> = {
  issued: 'bg-gradient-to-t from-[#4d4d4d] to-[#2e2e2e]',
  common: 'bg-gradient-to-t from-[#557a43] to-[#273822]',
  rare: 'bg-gradient-to-t from-[#7a4f9a] to-[#352640]',
  epic: 'bg-gradient-to-t from-[#a8922a] to-[#4a4114]',
}
