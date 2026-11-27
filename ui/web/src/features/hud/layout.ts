// Must match GameConst.HUD_MINIMAP_RECT on the Godot side: Godot draws the
// map texture in this rect under the page; the page only draws the frame.
export const MINIMAP = { left: 24, top: 40, width: 200, height: 170 } as const
export const COMPASS_WIDTH = 560
export const COMPASS_PX_PER_DEG = 4

// Rects from docs/ui-design/04-hud.md section 3 (1280 x 720 frame).
// Rows that the spec centres horizontally keep only top/width here and are
// centred with left-1/2, so they stay centred on wider frames.
export const SAFETY = { left: 240, top: 142, width: 208, height: 28 } as const
export const HEIST_ALERT = { top: 64, width: 400, height: 44 } as const
export const NOTIFICATIONS = { top: 116, width: 368 } as const
export const SURRENDER_HINT = { top: 594, width: 288, height: 32 } as const
export const REVIVE_PROGRESS = { top: 332, width: 416, height: 32 } as const
export const FINISH_WARNING = { top: 372, width: 416, height: 36 } as const

// Life and outcome surfaces (04-hud.md section 3): death/arrest/transfer panel,
// the compact receipt card on `/`, and the downed panel. Boxes keep their left;
// rows are centred with left-1/2 like the rows above.
export const OVERLAY_PANEL = { left: 408, top: 238, width: 464, height: 244 } as const
export const OVERLAY_TITLE = { top: 262, width: 416, height: 32 } as const
export const OVERLAY_SUMMARY = { top: 306, width: 416, height: 44 } as const
export const OVERLAY_STATUS = { top: 362, width: 416, height: 32 } as const
export const OVERLAY_PROGRESS = { top: 402, width: 416, height: 12 } as const
export const OVERLAY_FOOTER = { top: 418, width: 416, height: 40 } as const

export const RECEIPT_CARD = { left: 416, top: 260, width: 448, height: 164 } as const
export const RECEIPT_TITLE = { top: 272, width: 416, height: 28 } as const
export const RECEIPT_SUMMARY = { top: 308, width: 416, height: 44 } as const
export const RECEIPT_HINT = { top: 368, width: 416, height: 40 } as const

export const DOWNED_PANEL = { left: 416, top: 260, width: 448, height: 188 } as const
export const DOWNED_TITLE = { top: 272, width: 416, height: 28 } as const
export const BLEED_OUT = { top: 308, width: 416, height: 12 } as const
export const DOWNED_CONTROLS = { top: 416, width: 416, height: 20 } as const

// Must match GameConst.DOWNED_BLEEDOUT_SECONDS on the Godot side.
export const BLEED_OUT_SECONDS = 60
