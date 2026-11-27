import { describe, expect, it } from 'vitest'
import { applyUiScale, uiScale } from './uiScale'

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
