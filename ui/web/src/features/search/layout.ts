import { BAG_GRID } from '@/lib/grid/gridLayout'

// Body-search panel in screen px (04-hud.md "Body search with owner inventory" table;
// the page is pinned to 1280 x 720, so left 395 is the spec's right 558).
export const SEARCH_PANEL = { left: 395, top: 92, width: 327, height: 536 }
export const SEARCH_HEADER = { top: 92, height: 36 }
export const SEARCH_TITLE = { left: 406, width: 226 }
export const SEARCH_COUNT = { left: 638, width: 73 }
export const BODY_VIEWPORT = { left: 406, top: 128, width: BAG_GRID.width, height: BAG_GRID.height } // 305 x 458
export const BODY_SCROLLBAR = { left: 714, top: 128, width: 4, height: 458 }
export const SEARCH_FOOTER = { top: 592, height: 36 }
export const FOOTER_ROW = { top: 599, height: 22 }
export const FOOTER_ERROR = { left: 406, width: 135 }
export const FOOTER_CLOSE = { left: 548, width: 72 }
export const FOOTER_TAKE = { left: 627, width: 84 }
export const THUMB_MIN = 24
