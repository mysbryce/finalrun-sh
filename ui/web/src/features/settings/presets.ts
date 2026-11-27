import type { SettingValue } from '@/lib/ipc/protocol'

export type Preset = 'low' | 'medium' | 'high' | 'custom'
type Values = Record<string, SettingValue>

export const PRESET_KEYS = ['render_scale', 'shadows', 'textures', 'anti_aliasing', 'view_distance'] as const

/** docs/ui-design/03-settings.md, Graphics paragraph. */
export const PRESETS: Record<Exclude<Preset, 'custom'>, Values> = {
  low: { render_scale: 75, shadows: 'low', textures: 'low', anti_aliasing: 'off', view_distance: 'low' },
  medium: { render_scale: 100, shadows: 'medium', textures: 'medium', anti_aliasing: 'fxaa', view_distance: 'medium' },
  high: { render_scale: 100, shadows: 'high', textures: 'high', anti_aliasing: 'msaa_4x', view_distance: 'high' },
}

function isNamedPreset(p: unknown): p is Exclude<Preset, 'custom'> {
  return p === 'low' || p === 'medium' || p === 'high'
}

/** Selects `preset` and writes its five values (`custom` writes only the selection). */
export function applyPreset(draft: Values, preset: string): Values {
  const next: Values = { ...draft, quality_preset: preset }
  if (isNamedPreset(preset)) Object.assign(next, PRESETS[preset])
  return next
}

/** Sets one value; a preset member that leaves the selected preset switches it to `custom`. */
export function withManualChange(draft: Values, key: string, value: SettingValue): Values {
  const next: Values = { ...draft, [key]: value }
  const preset = next.quality_preset
  if ((PRESET_KEYS as readonly string[]).includes(key) && isNamedPreset(preset)) {
    const target = PRESETS[preset]
    if (PRESET_KEYS.some((k) => next[k] !== target[k])) next.quality_preset = 'custom'
  }
  return next
}
