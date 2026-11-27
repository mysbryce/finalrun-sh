import type { Prefs } from '@/lib/prefs'

// Must match project.godot window/size/viewport_width (canvas_items stretch base).
export const BASE_WIDTH = 1280

// 1 CSS px = 1 Godot canvas unit: zoom the page like Godot scales its canvas.
export function uiScale(innerWidth: number): number {
  return innerWidth > 0 ? innerWidth / BASE_WIDTH : 1
}

export function applyUiScale(): void {
  document.documentElement.style.zoom = String(uiScale(window.innerWidth))
}

// The ui_scale setting grows rem-based text and chrome; px-placed geometry stays pinned.
export function rootFontPx(percent: number): number {
  return (16 * percent) / 100
}

export function applyPrefs(prefs: Prefs): void {
  const root = document.documentElement
  root.style.fontSize = `${rootFontPx(prefs.uiScale)}px`
  if (prefs.colorblind === 'off') delete root.dataset.colorblind
  else root.dataset.colorblind = prefs.colorblind
}
