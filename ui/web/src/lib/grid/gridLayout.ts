export const TILE = 50 // bag slot size
export const GAP = 1
export const BAG_COLUMNS = 6
export const PITCH = TILE + GAP

export const BAG_ROWS = 9
export const BAG_GRID = { width: BAG_COLUMNS * TILE + (BAG_COLUMNS - 1) * GAP, height: BAG_ROWS * TILE + (BAG_ROWS - 1) * GAP } // 305 x 458

// CSS px box of an item (or cell) whose top-left cell is `slot`.
export function cellBox(slot: number, w = 1, h = 1) {
  const col = slot % BAG_COLUMNS
  const row = Math.floor(slot / BAG_COLUMNS)
  return { left: col * PITCH, top: row * PITCH, width: w * TILE + (w - 1) * GAP, height: h * TILE + (h - 1) * GAP }
}
