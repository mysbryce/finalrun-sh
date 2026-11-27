import { describe, expect, it } from 'vitest'
import { PRESETS, applyPreset, withManualChange } from './presets'

const MEDIUM = { quality_preset: 'medium', ...PRESETS.medium, fov: 75 }

describe('presets', () => {
  it('applyPreset writes the five values', () => {
    expect(applyPreset(MEDIUM, 'low')).toEqual({
      quality_preset: 'low',
      render_scale: 75,
      shadows: 'low',
      textures: 'low',
      anti_aliasing: 'off',
      view_distance: 'low',
      fov: 75,
    })
    expect(applyPreset(MEDIUM, 'high')).toMatchObject({ anti_aliasing: 'msaa_4x', shadows: 'high' })
  })

  it('custom writes nothing but the selection', () => {
    expect(applyPreset(MEDIUM, 'custom')).toEqual({ ...MEDIUM, quality_preset: 'custom' })
  })

  it('a manual preset-member change selects custom', () => {
    expect(withManualChange(MEDIUM, 'shadows', 'high')).toMatchObject({ shadows: 'high', quality_preset: 'custom' })
  })

  it('a change back to the preset value keeps the preset', () => {
    expect(withManualChange(MEDIUM, 'shadows', 'medium').quality_preset).toBe('medium')
  })

  it('a non-member change keeps the preset', () => {
    expect(withManualChange(MEDIUM, 'fov', 90)).toEqual({ ...MEDIUM, fov: 90 })
  })

  it('a member change while custom stays custom', () => {
    const custom = { ...MEDIUM, quality_preset: 'custom' }
    expect(withManualChange(custom, 'textures', 'high').quality_preset).toBe('custom')
  })
})
