import { create } from 'zustand'

export type Colorblind = 'off' | 'protanopia' | 'deuteranopia' | 'tritanopia'

/** Page-side display preferences, fed from every `settings` snapshot by the app layer. */
export interface Prefs {
  uiScale: number
  colorblind: Colorblind
  showCompass: boolean
  minimapRotate: boolean
}

export const DEFAULT_PREFS: Prefs = { uiScale: 100, colorblind: 'off', showCompass: true, minimapRotate: false }

export const usePrefs = create<Prefs>(() => DEFAULT_PREFS)

const COLORBLIND: readonly Colorblind[] = ['off', 'protanopia', 'deuteranopia', 'tritanopia']

export function prefsFromValues(values: Record<string, unknown>): Prefs {
  const scale = values.ui_scale
  const mode = values.colorblind_mode
  const compass = values.show_compass
  const rotate = values.minimap_rotate
  return {
    uiScale: Number.isInteger(scale) && (scale as number) >= 90 && (scale as number) <= 110 ? (scale as number) : 100,
    colorblind: COLORBLIND.includes(mode as Colorblind) ? (mode as Colorblind) : 'off',
    showCompass: typeof compass === 'boolean' ? compass : true,
    minimapRotate: typeof rotate === 'boolean' ? rotate : false,
  }
}
