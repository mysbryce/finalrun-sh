import { describe, expect, it } from 'vitest'
import { DEFAULT_PREFS, prefsFromValues } from './prefs'

describe('prefsFromValues', () => {
  it('returns the defaults for empty values', () => {
    expect(prefsFromValues({})).toEqual(DEFAULT_PREFS)
  })

  it('passes valid values through', () => {
    expect(
      prefsFromValues({ ui_scale: 110, colorblind_mode: 'tritanopia', show_compass: false, minimap_rotate: true }),
    ).toEqual({ uiScale: 110, colorblind: 'tritanopia', showCompass: false, minimapRotate: true })
  })

  it('falls back to 100 for an out-of-range ui_scale', () => {
    expect(prefsFromValues({ ui_scale: 150 }).uiScale).toBe(100)
  })

  it('falls back to off for an unknown colorblind_mode', () => {
    expect(prefsFromValues({ colorblind_mode: 'mono' }).colorblind).toBe('off')
  })

  it('falls back to true for a non-boolean show_compass', () => {
    expect(prefsFromValues({ show_compass: 'no' }).showCompass).toBe(true)
  })
})
