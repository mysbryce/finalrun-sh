import { describe, expect, it } from 'vitest'
import { contrastRatio } from './contrast'

const zinc100 = '#f4f4f5'
const zinc300 = '#d4d4d8'
const zinc800 = '#27272a'
const zinc900 = '#18181b'
const zinc950 = '#09090b'
const amber400 = '#fbbf24'

describe('contrastRatio', () => {
  it('black on white is 21', () => {
    expect(contrastRatio('#000000', '#ffffff')).toBeCloseTo(21, 5)
  })

  it('token pairs hold', () => {
    expect(contrastRatio(zinc100, zinc900)).toBeGreaterThanOrEqual(15)
    expect(contrastRatio(zinc300, zinc800)).toBeGreaterThanOrEqual(9)
    expect(contrastRatio(zinc900, amber400)).toBeGreaterThanOrEqual(9)
  })

  it('every body pair is at least 4.5', () => {
    const pairs: [string, string][] = [
      [zinc100, zinc900],
      [zinc100, zinc800],
      [zinc100, zinc950],
      [zinc300, zinc900],
      [zinc300, zinc800],
      [zinc300, zinc950],
      [zinc900, amber400],
    ]
    for (const [fg, bg] of pairs) expect(contrastRatio(fg, bg)).toBeGreaterThanOrEqual(4.5)
  })
})
