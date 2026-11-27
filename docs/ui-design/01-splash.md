# 01 · Splash and boot

## 1. Purpose and entry/exit

Prepare required client resources, the browser, and an optional connection while keeping the user informed. Main starts with a native fallback using the same center stack and version position. After the browser sends `ready`, Godot can route to `/splash`. The host routes to `/lobby` once required readiness gates pass. Dedicated and headless starts use the existing non-CEF execution path.

## 2. ASCII wireframes

### Splash and boot

[Open SVG](wireframes/01-splash.svg)

```text
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                                                                                               |
|                             +-----------------------------------+                             |
|                             | +Studio label-------------------+ |                             |
|                             | +-------------------------------+ |                             |
|                             | |Game title                     | |                             |
|                             | +-------------------------------+ |                             |
|                             +-----------------------------------+                             |
|                             ++Stage label----------------------++                             |
|                             |+Loading progress-----------------+|                             |
|                             |+Boot detail----------------------+|                             |
|                             |+---------------------------------+|                             |
|                             +-----------------------------------+                             |
|                              +Primary action-+ +Offline action-+                              |
|                              +----------++---------++----------+                              |
|                              |A14       ||A15      ||A16       |                              |
|                              +----------++---------++----------+                              |
|                                                                                               |
| +Skip hint--------+                                                       +Version----------+ |
| +-----------------+                                                       +-----------------+ |
+-----------------------------------------------------------------------------------------------+

[A01 Splash surface]
  [A02 Title card]
    [A03 Studio label]
    [A04 Game title]
  [A05 Boot state]
    [A06 Stage label]
    [A07 Loading progress]
    [A08 Boot detail]
  [A09 Primary action]
  [A10 Offline action]
  [A11 Skip hint]
  [A12 Version]
  [A13 Boot stage rail]
    [A14 Assets stage]
    [A15 Interface stage]
    [A16 Connection stage]
```

## 3. Layout

Right and bottom give offsets to the base-frame edges. Group bounds intentionally contain their children. Rows and regions use base CSS pixels.

### Splash and boot

| ID | Element | Left | Top | Right | Bottom | Width | Height | Parent |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A01 | Splash surface | 0 | 0 | 0 | 0 | 1280 | 720 | Frame |
| A02 | Title card | 400 | 208 | 400 | 384 | 480 | 128 | Splash surface |
| A03 | Studio label | 432 | 224 | 432 | 472 | 416 | 24 | Title card |
| A04 | Game title | 432 | 258 | 432 | 406 | 416 | 56 | Title card |
| A05 | Boot state | 400 | 368 | 400 | 232 | 480 | 120 | Splash surface |
| A06 | Stage label | 416 | 380 | 416 | 316 | 448 | 24 | Boot state |
| A07 | Loading progress | 416 | 412 | 416 | 296 | 448 | 12 | Boot state |
| A08 | Boot detail | 416 | 440 | 416 | 248 | 448 | 32 | Boot state |
| A09 | Primary action | 416 | 504 | 648 | 176 | 216 | 40 | Splash surface |
| A10 | Offline action | 648 | 504 | 416 | 176 | 216 | 40 | Splash surface |
| A11 | Skip hint | 24 | 664 | 1008 | 24 | 248 | 32 | Splash surface |
| A12 | Version | 1008 | 664 | 24 | 24 | 248 | 32 | Splash surface |
| A13 | Boot stage rail | 416 | 556 | 416 | 124 | 448 | 40 | Splash surface |
| A14 | Assets stage | 416 | 556 | 720 | 124 | 144 | 40 | Boot stage rail |
| A15 | Interface stage | 568 | 556 | 568 | 124 | 144 | 40 | Boot stage rail |
| A16 | Connection stage | 720 | 556 | 416 | 124 | 144 | 40 | Boot stage rail |

The title and progress surfaces stay fixed between stages. Retry uses the primary action slot on failure. Continue Offline uses the adjacent offline action slot only when connection can be abandoned. Keep the stage rail 448 px wide and update its three cells in place.

## 4. States

| State | Display and behavior |
|---|---|
| Title | Show configured studio label when available and FinalRun as title. Missing studio name leaves the slot empty. Minimum dwell 800 ms, skippable after 250 ms. |
| Asset load | Begin alongside title. Show required-work counts when meaningful using integer floor(done ÷ total × 100). No progress guess for unknown work. A 30 s watchdog yields failure if required assets are stalled. |
| CEF load | Use “Loading interface” until `ready`. Allow 15 s per attempt. Native fallback stays visible and handles recovery if browser startup fails. |
| Connecting | Only when the host has an explicit endpoint for this run. Show “Connecting to server” with indeterminate progress and a 12 s timeout. On normal startup, route offline to lobby after required assets and CEF. Mark optional Connection stage “Skipped.” |
| Ready | Render 100% only for a known completed total. Wait out remaining title dwell unless skipped. Change route on the first valid host update. |
| Failure | Stage rail marks active failure. Show readable reason, Retry when supported, and Continue Offline for terminal connection failure. Native fatal asset/CEF failure offers retry and OS window close. |
| Retry disabled | After selection, lock Retry until a new attempt starts or fails. No overlapping attempts. |
| Missing version | Render “Development build” with no fabricated ID. Version remains visible in all states. |

## 5. Interactions

Click Retry or Continue Offline when offered. Press Enter to skip title only in the eligible interval and consume that keypress. Loading phases suppress keyboard shortcuts. On failure focus Retry, then Continue Offline when available. Escape closes active subdialogs only, except native Escape may continue offline when that action is offered. An explicit native fallback action remains usable if CEF cannot render. Gamepad later.

## 6. Data

`boot` supplies `BootView.phase`, `version`, `buildId`, `progress`, `connectOnBoot`, `canSkipTitle`, `error` and `canRetry`. Send `boot.skip`, `boot.retry` or `boot.continue`. Observe `route` from the host. Browser `ready` contributes to the readiness gate.

## 7. Godot side

Existing client startup and connection callbacks live in [Main.gd](../../main/Main.gd). Existing browser readiness and version-independent page URL selection live in [Hud.gd](../../ui/hud/Hud.gd). **NEW** Main-owned Boot coordinator supplies phase, configured version, load counters and fallback actions. It passes a snapshot to Hud after CEF connects.

## 8. Accessibility

Use body ≥14 px and version ≥11 px. Ensure ≥4.5:1 contrast. Focus ring surrounds the active button and survives mode changes. Announce stage changes politely and terminal errors once. Keep percentage updates silent between 10% steps. Completed, active, skipped and failed stages include readable labels. Reduced motion keeps pending text static.

## 9. Open questions

1. Approve proposed 800 ms title dwell and 250 ms skip threshold. Confirm studio display string and build ID source.
2. Confirm whether launch accepts an explicit connection target in release or always starts offline.
3. Agree on watchdog thresholds and native fallback recovery copy.
