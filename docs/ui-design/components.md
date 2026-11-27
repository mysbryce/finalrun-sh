# UI components

Dimensions are base px. Page components receive display props and event callbacks. Host routing and gameplay outcomes follow [flow](flow.md) and [data contracts](DATA_CONTRACTS.md). Meaningful status always gets a visible label. A focusable control uses the token ring, including during a mouse operation when focus was reached by keyboard.

| Component | Size and props | Default / hover / focus / active / disabled / error |
|---|---|---|
| Panel | Route-defined width/height, 16 inset on lobby, 24 modal, 12 inventory. `title, children, compact, surface, busy`. | Default zinc-900. Container has no hover or focus. Active child carries selection. Busy skeleton keeps bounds. Error slot preserves title. |
| Header bar | 56 px standard, 36 compact. `title, subtitle?, leading?, trailing?, status?`. | Static label. Interactive child inherits button states. Loading uses fixed title slot, with live error copy when applicable. |
| Tab bar | 44 px, equal tabs, 2 px underline. `tabs, selectedId, onSelect`. | Neutral label, hover raised fill, focus ring, selected underline and `aria-selected`. Disabled tab skipped. Tab error uses text marker. |
| Button | 40 × ≥88 primary/secondary, 36 compact, 22 legacy inventory footer. `label, variant, disabled, loading, onPress, describedBy?`. | Primary amber, secondary zinc edge, quiet text, destructive neutral with explicit verb. Hover lifts fill. Focus ring. Active inset edge. Disabled keeps label. Pending locks repeat. Error helper sits by action. |
| Slider | 36 px row control, 4 px track, 14 px thumb, 64 px readout. `value, min, max, step, unit, onChange`. | Amber fill to value, hover track edge, focus ring, pressed hold. Disabled shows value. Error preserves last valid value. Arrow steps, Home/End endpoints, PageUp/Down 5 steps. |
| Toggle | 48 × 24 track with 18 px thumb in 36 px hit area and adjacent On/Off. `checked, onChange, disabled, description`. | Off zinc, On amber thumb with label, hover edge, focus ring, active inset edge. Locked state and error reason in text. |
| Dropdown | 36 px trigger, menu width at least trigger width, max 224 px high, 32 px option. `value, options, onChange, disabled, error`. | Current value and disclosure mark, hover tint, focus ring, active option rule, disabled choices show reason. Arrow keys navigate, Enter selects, Escape closes, typing searches. |
| Key-hint chip | 20 px high, ≥20 wide with 4 horizontal inset. `binding, label, announce`. | Static chip. Hover/focus/active/disabled/error are inherited when nested in a button. Unbound uses visible text. |
| Keybind row | 48 high, 52 pitch, 36 px trigger. `action, binding, editable, onCapture, issue`. | Binding value or Unbound, hover row edge, focus trigger ring, active capture dialog, fixed label or disabled “Coming later” tag, conflict with both action names. |
| Item tile | `50w + (w - 1)` by `50h + (h - 1)`. `uid, label, value, rarity, w, h, selected, pending, onSelect`. | Neutral empty cell, rarity edge on filled tile, hover edge, focus ring, active amber selection, pending dims, invalid drop explicit outline and status. |
| Progress bar | 12 px default, 4 px compact; 4 × 4 px-high segments for health. `label, value?, max, status, showValue`. | Determinate fill, indeterminate static segmented track and status under reduced motion, unavailable outline, error with explicit cause. Display progress has no interactive state. |
| Toast | 368 × 24, up to four with 4 px gap. `id?, text, priority, durationMs`. | One text line in tray with polite announcement, newest bottom. Hover/focus/active absent. Empty hides tray. Heist event toast lasts 8 s and is paired with an active alert line. |
| Modal | 512 × 256 at (384,232), 24 px inset, 40 px actions. `title, body, primary, secondary, dismissible, busy`. | Dim 55%, focus trap, default focus on safest action for destructive flows, pending protects action, inline error near body. Modal Escape returns to originating control. |
| Stage rail | 448 × 40, three 144 px cells with 8 px gaps. `phase, label, completed`. | Completed check and short label, current 2 px rule, upcoming neutral, failed current stage marked Failed. Display-only. |
| Status badge | 112 × 28 in HUD, 208 × 28 for the weapons-lock copy; height 28 in lists. `label, icon?, status`. | Plain text, optional status tint and marker, no interaction. A pending state retains label. |
| Party member frame | 240 × 48 in HUD, 368 × 44 in Pause and future staging. `name, leader, life, health, maxHealth, away`. | Name and leader mark, four health segments, Away text and no meter if absent. Kick is a separate server-gated button. Incoming invite includes remaining seconds and Accept/Decline. |
| Compass | 560 × 32. `heading, visible`. | Fixed center tick, moving 15° ticks, cardinal labels every 45°. Hidden from focus. Use heading text for screen-reader lookup. |

For dialog or list failures, render a friendly description and recovery action where safe. Keep a machine error code in the developer console and avoid surfacing raw errors in visible copy. Escape within a popover or capture closes its own layer before navigating back. Restore focus to the row or invoking button.


Outcome receipts use a 464 × 244 standalone panel or a 448 × 164 compact card above a fresh HUD, following the HUD layout tables. Props are `receiptId, remainingMs, kind, cause, onDismiss`. They keep one 900 ms host deadline across route changes and accept Escape/click dismissal. Captured gameplay dismissal is intercepted by Godot.
