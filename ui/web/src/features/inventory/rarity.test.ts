import { describe, expect, it } from 'vitest'
import { rarityOf } from './rarity'

describe('rarityOf', () => {
  it('maps values to rarity', () => {
    expect(rarityOf(0)).toBe('issued')
    expect(rarityOf(249)).toBe('common')
    expect(rarityOf(250)).toBe('rare')
    expect(rarityOf(599)).toBe('rare')
    expect(rarityOf(600)).toBe('epic')
  })
})
