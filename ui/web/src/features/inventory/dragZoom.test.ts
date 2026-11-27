import { afterEach, describe, expect, it } from 'vitest'
import { pageZoom, unzoom } from './dragZoom'

describe('unzoom', () => {
  const t = { x: 30, y: -60, scaleX: 1, scaleY: 1 }

  it('returns the same transform at zoom 1', () => {
    expect(unzoom(t, { left: 600, top: 300 }, 1)).toBe(t)
  })

  it('cancels the page zoom', () => {
    const r = unzoom(t, { left: 600, top: 300 }, 1.5)
    expect(r.x).toBeCloseTo(-180)
    expect(r.y).toBeCloseTo(-140)
    expect(r.scaleX).toBe(1)
    expect(r.scaleY).toBe(1)
  })

  it('returns the transform when rect is null', () => {
    expect(unzoom(t, null, 1.5)).toBe(t)
  })
})

describe('pageZoom', () => {
  afterEach(() => {
    document.documentElement.style.zoom = ''
  })

  it('reads the zoom on <html>', () => {
    document.documentElement.style.zoom = '1.5'
    expect(pageZoom()).toBe(1.5)
  })

  it('is 1 when unset', () => {
    document.documentElement.style.zoom = ''
    expect(pageZoom()).toBe(1)
  })
})
