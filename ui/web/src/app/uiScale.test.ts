import { describe, expect, it } from 'vitest'
import { DEFAULT_PREFS } from '@/lib/prefs'
import { applyPrefs, applyUiScale, rootFontPx, uiScale } from './uiScale'

describe('uiScale', () => {
  it('matches the Godot canvas scale at 1600 px', () => {
    expect(uiScale(1600)).toBe(1.25)
  })

  it('is 1 at the 1280 px base width', () => {
    expect(uiScale(1280)).toBe(1)
  })

  it('falls back to 1 for a zero width', () => {
    expect(uiScale(0)).toBe(1)
  })

  it('zooms the page to the canvas scale', () => {
    Object.defineProperty(window, 'innerWidth', { value: 1920, configurable: true })
    applyUiScale()
    expect(document.documentElement.style.zoom).toBe('1.5')
  })
})

describe('applyPrefs', () => {
  it('maps the ui_scale percent to a root font size', () => {
    expect(rootFontPx(110)).toBe(17.6)
    expect(rootFontPx(90)).toBe(14.4)
  })

  it('sets the root font size', () => {
    applyPrefs({ ...DEFAULT_PREFS, uiScale: 110 })
    expect(document.documentElement.style.fontSize).toBe('17.6px')
  })

  it('sets and removes the colorblind data attribute', () => {
    applyPrefs({ ...DEFAULT_PREFS, colorblind: 'tritanopia' })
    expect(document.documentElement.dataset.colorblind).toBe('tritanopia')
    applyPrefs({ ...DEFAULT_PREFS, colorblind: 'off' })
    expect(document.documentElement.dataset.colorblind).toBeUndefined()
  })
})
