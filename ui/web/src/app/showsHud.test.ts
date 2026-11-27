import { describe, expect, it } from 'vitest'
import { showsHud } from './showsHud'

describe('showsHud', () => {
  it('hides the HUD on full screens', () => {
    for (const path of ['/death', '/arrest', '/transfer', '/inventory', '/splash', '/lobby', '/settings/graphics']) {
      expect(showsHud(path)).toBe(false)
    }
  })

  it('shows the HUD elsewhere', () => {
    for (const path of ['/', '/search', '/pause']) {
      expect(showsHud(path)).toBe(true)
    }
  })
})
