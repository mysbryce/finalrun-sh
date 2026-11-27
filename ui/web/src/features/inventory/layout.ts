import { GAP, TILE } from '@/lib/grid/gridLayout'

// In-raid panel (ROB RUN export: 784 x 804, right 38, header/footer 54, x 2/3).
export const PANEL = { right: 25, top: 92, width: 524, height: 536, header: 36, footer: 36, inset: 12 }
export const BAG_COL = { left: PANEL.inset, top: PANEL.header } // grid BAG_GRID (305 x 458)
export const EQUIP_COL = { width: 183, left: PANEL.width - PANEL.inset - 183, top: PANEL.header }
// Equipment slot boxes inside EQUIP_COL (reference: weapons 274x132, vest/backpack 132x132,
// belt 108x150, pockets 74 px with 76 pitch, bottom row 150 high at the column bottom).
export const EQUIP_SLOTS = {
  primary: { left: 0, top: 0, w: 183, h: 88 },
  secondary: { left: 0, top: 95, w: 183, h: 88 },
  armor: { left: 0, top: 190, w: 88, h: 88 },
  bag: { left: 95, top: 190, w: 88, h: 88 },
  pouchLabel: { left: 0, top: 284 },
  pouch: { left: 0, top: 304, w: 72, h: 100 },
  pockets: { left: 183 - (2 * TILE + GAP), top: 304 }, // 2x2 grid of TILE cells, GAP apart
}
