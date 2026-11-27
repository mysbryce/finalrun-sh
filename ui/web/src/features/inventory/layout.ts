export const TILE = 50 // bag slot size
export const GAP = 1
export const TITLE = { left: 26, top: 26 }
export const TABS = { left: 26, top: 96 }
export const DETAILS = { left: 80, top: 155, width: 405, height: 470 }
export const BAG = { left: 700, top: 155 } // width = 6 * TILE + 5 * GAP
export const EQUIPMENT = { left: 1017, top: 155, width: 183 }
export const FOOTER_HEIGHT = 36
export const BAG_COLUMNS = 6
export const PITCH = TILE + GAP

// CSS px box of an item (or cell) whose top-left cell is `slot`.
export function cellBox(slot: number, w = 1, h = 1) {
  const col = slot % BAG_COLUMNS
  const row = Math.floor(slot / BAG_COLUMNS)
  return { left: col * PITCH, top: row * PITCH, width: w * TILE + (w - 1) * GAP, height: h * TILE + (h - 1) * GAP }
}
