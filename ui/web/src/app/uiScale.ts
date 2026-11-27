// Must match project.godot window/size/viewport_width (canvas_items stretch base).
export const BASE_WIDTH = 1280

// 1 CSS px = 1 Godot canvas unit: zoom the page like Godot scales its canvas.
export function uiScale(innerWidth: number): number {
  return innerWidth > 0 ? innerWidth / BASE_WIDTH : 1
}

export function applyUiScale(): void {
  document.documentElement.style.zoom = String(uiScale(window.innerWidth))
}
