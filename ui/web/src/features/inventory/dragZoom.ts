import type { Modifier } from '@dnd-kit/core'

// The page zoom set on <html> by app/uiScale.ts (1 when unset).
export function pageZoom(): number {
  const z = Number.parseFloat(document.documentElement.style.zoom)
  return Number.isFinite(z) && z > 0 ? z : 1
}

// DragOverlay is position: fixed at `left/top` (screen px) plus the transform, and
// the zoomed <html> scales both again. Returns the transform that puts the overlay
// at (left + x, top + y) on screen.
export function unzoom(
  t: { x: number; y: number; scaleX: number; scaleY: number },
  rect: { left: number; top: number } | null,
  zoom: number,
) {
  if (!rect || zoom === 1) return t
  return { ...t, x: (rect.left + t.x) / zoom - rect.left, y: (rect.top + t.y) / zoom - rect.top }
}

export const unzoomModifier: Modifier = ({ transform, activeNodeRect }) =>
  unzoom(transform, activeNodeRect, pageZoom())
