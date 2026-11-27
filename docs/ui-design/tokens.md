# UI tokens

All sizes are base CSS px. Use the system stack `system-ui, -apple-system, "Segoe UI", sans-serif`. Display text stays upright. Set numeric timers, currency and health in tabular numerals.

| Token | Values | Use |
|---|---|---|
| Spacing | 0, 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64 px | 8 px layout rhythm with compact 4/6 px splits. Exact HUD and grid offsets follow their tables. |
| Caption | 11/16 px, 500 | Key chips, status and network labels |
| Body compact | 12/16 px, 400 | Dense lists and help |
| Body | 14/20 px, 400 | Ordinary copy, controls |
| Label | 14/20 px, 600 | Panel and form labels |
| Panel heading | 18/24 px, 650 | Inventory and HUD panel headings |
| Screen heading | 24/32 px, 650 | Lobby, settings and outcomes |
| Title | 48/56 px, 700 | Splash |
| Tracking | 0 px body, 0.5 px uppercase, 0.8 px counter caps | One line per label |
| Radii | 2, 4, 6, 8 px | Cell, control, panel, modal |
| Borders | 1 px neutral rails, 2 px selection or focus | Keep dedicated geometry for the focus offset |
| Focus ring | 2 px amber-400 with 2 px zinc-950 offset | Draw around whole target. Keep 4 px scroll clearance. |
| Elevation | 0–4 px soft shade under card, 12 px blur under modal | Reserve raster blur in CEF for the existing inventory surface and opt out on low quality. |

| Tailwind token | Hex | Role |
|---|---|---|
| zinc-950 | `#09090b` | HUD text plate base, full screen backdrop |
| zinc-900 | `#18181b` | Panels, modal surface, amber text foreground |
| zinc-800 | `#27272a` | Raised control and row surface |
| zinc-700 | `#3f3f46` | Secondary edge and hover outline |
| zinc-500 | `#71717a` | Strong neutral control edge on zinc-950 |
| zinc-300 | `#d4d4d8` | Secondary text |
| zinc-100 | `#f4f4f5` | Body and strong labels |
| amber-400 | `#fbbf24` | Primary action, focus, current heading, selected slot, epic rarity |
| zinc-300 | `#d4d4d8` | Issued rarity |
| emerald-400 | `#34d399` | Common rarity and optional health |
| violet-400 | `#a78bfa` | Rare rarity |
| red-400 | `#f87171` | Optional danger status tint |
| blue-400 | `#60a5fa` | Optional Cop status tint |

Rarity thresholds by value are issued at ≤ 0, common below 250, rare below 600, epic from 600. Use tint on a 2 px edge and repeat the rarity in text where space permits. Role and health tints carry redundant names or numeric meters. Amber stays the single interaction accent. Zinc-100 on zinc-900 is about 16:1, zinc-300 on zinc-800 about 10:1, and zinc-900 on amber-400 about 10:1. Composite HUD body copy over a local near-opaque backing or inverse outline as needed to hold at least 4.5:1 on bright scenes. Keep current inventory geometry and panel blur. Provide contrast using chip or text treatment within those bounds.

| Layer | Z | Contents |
|---|---:|---|
| World | 0 | Godot world and minimap texture |
| Read-only HUD | 10 | Frame, labels and meters |
| Context and alert | 20 | Interaction card, heist alert and toasts |
| Panel | 30 | Settings, lobby, inventory, search and pause content |
| Popover | 40 | Dropdowns, picker, item drag preview |
| State | 50 | Downed, arrest/death receipts and map transfer |
| Dialog | 60 | Active confirmation, capture and consent |
| Focus treatment | Local | Render above its control within the owning layer |

| Motion | Timing | Behavior |
|---|---|---|
| Hover, active and focus | 80 ms | Change border and fill. Show keyboard ring immediately. |
| Row/state reveal | 120 ms ease-out | Fade from 0.75 to 1 opacity. Optional transform ≤ 4 px. |
| Panel/route change | 160 ms ease-out | Fade old content then replace within one transition. Focus after the destination can receive it. |
| Toast | 120 ms in, 100 ms out | Stack updates in place. Ordinary display time is 4 s by default; heist event toast uses 8 s, with its alert line active until server clear. |
| Numeric progress catch-up | ≤ 100 ms | Interpolate display only. Snap authoritative decreases or stage changes. |
| Reduced motion | 0 ms | Instant state and static pending text. No oscillation, scroll animation or blur transition. |

CEF surface pixels use the existing width ratio `innerWidth / 1280`. The separate UI-scale setting changes eligible text and chrome within their existing bounds. Keep Godot's minimap frame and inventory grid tied to the base coordinates.
