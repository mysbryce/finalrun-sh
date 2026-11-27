# HUD layout

Owner decision 2026-11-27: the in-game HUD uses the same screen layout as ROB RUN (Kefir, 2026), studied from its Steam store screenshots. We copy **where things sit and what they show** (a genre-standard arrangement). Art, icons, fonts and colors are our own: no copied assets, logos or exact styling.

## Reference layout (observed in ROB RUN screenshots)
| Zone | What it shows |
|---|---|
| Top-left, line 1 | `FPS: 60  PING: 40MS  LOSS: 0%` small text |
| Top-left, below | Square minimap (north-up, player arrow, map icons) |
| Right of minimap | Criminal timer pill (mm:ss), status icons |
| Top-center | Horizontal compass strip (N 15 30 NE ...), tick at center |
| Under compass | Big event banners (e.g. jail time) |
| Top-right | Cash amount |
| Bottom-left | Party members (name + segmented health bar), own name + health bar last, then a small icon row (level, bonuses) with key hints |
| Bottom-right | Hotbar: 2 wide weapon slots + 4 small item slots, number keys 1-6 under them, selected slot outlined; bag button (TAB) at the end |
| Right edge, lower | Small round buttons with key hints (emotes B, help K) |
| World | Interact card near the target: title, then `[E] action` rows; name tags over players |

## Our HUD (zones, data, status)
Pixel numbers are CSS px at 1:1 with the game window (CEF renders at window size).

| Zone | Our content | Data (HudState field) | Now |
|---|---|---|---|
| Top-left line | `FPS 60 · PING 40 ms` | `net.fps`, `net.ping` | yes |
| Top-left box (left 24, top 40, 200 x 170) | Minimap: Godot draws the map under the page in this exact rect (north-up top-down ortho camera); the page draws only the frame and the player arrow rotated by `heading` | `heading` | yes (card 03) |
| Right of minimap | Timer pill: `MASKING 0:02`; role badge and notoriety chip under it | `timer`, `role`, `notoriety` | yes |
| Top-center | Compass strip, 15° ticks, labels at 45°, centered on `heading` | `heading` | yes |
| Under compass | Notification toasts (newest last); bleed-out is a large banner here while DOWNED | `notifications`, `timer` + `life` | yes |
| Top-right | Cash | `cash` | yes |
| Bottom-left | Party members (name, health bar, leader mark, "away" when not in our instance), then own name + health bar | `party[]`, `self`, `health`, `maxHealth`, `life` | yes |
| Bottom-right | Hotbar 6 slots (keys 1-6), slot 1 active; bag button `TAB` with bag value | `hotbar[]`, `activeSlot`, `bag` | slot 1 only (one weapon today) |
| Right edge | Emote / help buttons | none | no: add with those features |
| World | Interact card: title + `[key] action` rows, bottom-center-ish (we do not project to the target yet) | `interact` | yes |
| World | Name tags | none | no: needs player names |

## HudState v2 (Godot → page `hud` message)
```json
{
  "role": "CRIMINAL", "life": "ALIVE",
  "health": 75, "maxHealth": 100,
  "cash": 50, "bag": 500, "notoriety": 500,
  "heading": 312,
  "timer": {"label": "Masking", "seconds": 2},
  "interact": {"title": "Loot crate", "actions": [{"key": "E", "label": "lockpick"}, {"key": "V", "label": "smash"}]},
  "notifications": ["Looted $300 (silent)"],
  "self": {"name": "Player 2"},
  "party": [{"name": "Player 3", "health": 100, "maxHealth": 100, "life": "ALIVE", "leader": true, "away": false}],
  "hotbar": [{"label": "Pistol"}, null, null, null, null, null],
  "activeSlot": 0,
  "net": {"fps": 60, "ping": 40}
}
```
- `heading`: degrees 0-359, 0 = north = world -Z, 90 = east = +X, from the active camera yaw.
- `interact`: `null` when nothing is in reach or the player is not ALIVE. Built from `InteractArea.title` and `InteractArea.prompt` (`"E lockpick | V smash"` → actions).
- `party`: other members only (self excluded). `away: true` (health -1) when the member is not in our instance.
- Names are `"Player <peer id>"` until a name system exists.

## Visual style (ours)
Dark translucent panels (`bg-zinc-950/60`, `rounded-md`, thin `ring-white/10`), white text, accent amber (`amber-400`) for the active slot, key chips and compass center; role colors: CITIZEN zinc, CRIMINAL red, COP blue. Health bar: 4 segments, emerald, red under 30 %. System font, uppercase semibold labels with wide tracking. Theme can change later without touching the layout.
