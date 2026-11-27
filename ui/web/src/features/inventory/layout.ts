export const TILE = 50 // bag slot size
export const GAP = 1
export const FOOTER_HEIGHT = 36
export const BAG_COLUMNS = 6
export const PITCH = TILE + GAP

export const TITLE = { left: 25, top: 32 }
export const TABS = { left: 25, top: 95, width: 132, height: 27 }
export const CASH = { right: 23, top: 29, height: 25 }
export const PANEL_TOP = 155
export const HEADER_HEIGHT = 33
export const HEADER_GAP = 11 // header bar -> panel content
export const BAG_ROWS = 9
export const BAG_GRID = { width: BAG_COLUMNS * TILE + (BAG_COLUMNS - 1) * GAP, height: BAG_ROWS * TILE + (BAG_ROWS - 1) * GAP } // 305 x 458
export const DETAILS = { left: 80, top: PANEL_TOP, width: 405 }
export const BAG = { left: 701, top: PANEL_TOP }
export const EQUIPMENT = { left: 1017, top: PANEL_TOP, width: 183, wide: { w: 183, h: 88 }, square: { w: 88, h: 88 }, gap: 7, pouch: { w: 72, h: 101 }, pouchGap: 11 }

// CSS px box of an item (or cell) whose top-left cell is `slot`.
export function cellBox(slot: number, w = 1, h = 1) {
  const col = slot % BAG_COLUMNS
  const row = Math.floor(slot / BAG_COLUMNS)
  return { left: col * PITCH, top: row * PITCH, width: w * TILE + (w - 1) * GAP, height: h * TILE + (h - 1) * GAP }
}
