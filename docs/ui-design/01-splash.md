# 01 · Splash and boot

## 1. Purpose and entry/exit

Prepare required client assets and the browser, then connect to the configured endpoint at boot. Development defaults to 127.0.0.1:7777. The user argument `--connect host:port` overrides the configured endpoint in every build. Main shows a native fallback until CEF can render `/splash`. Once assets, CEF and the connection are ready, continue directly through `/transfer` into Motel. Connection failures retain Retry and Quit. The lobby is available after leaving an established session or recovering from a later disconnect. Dedicated/headless startup uses the existing non-CEF path.

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
|                              +Primary action-+ +Quit action----+                              |
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
  [A10 Quit action]
  [A11 Skip hint]
  [A12 Version]
  [A13 Boot stage rail]
    [A14 Assets stage]
    [A15 Interface stage]
    [A16 Connection stage]
```

## 3. Layout

Right and bottom are insets from the 1280 × 720 frame. Parent bounds contain their children. Each drawing is a separate state.

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
| A10 | Quit action | 648 | 504 | 416 | 176 | 216 | 40 | Splash surface |
| A11 | Skip hint | 24 | 664 | 1008 | 24 | 248 | 32 | Splash surface |
| A12 | Version | 1008 | 664 | 24 | 24 | 248 | 32 | Splash surface |
| A13 | Boot stage rail | 416 | 556 | 416 | 124 | 448 | 40 | Splash surface |
| A14 | Assets stage | 416 | 556 | 720 | 124 | 144 | 40 | Boot stage rail |
| A15 | Interface stage | 568 | 556 | 568 | 124 | 144 | 40 | Boot stage rail |
| A16 | Connection stage | 720 | 556 | 416 | 124 | 144 | 40 | Boot stage rail |

The Retry and Quit slots appear only on failure. Required stage cells remain in Assets → Interface → Connection order. Title skipping changes only dwell time. Keep the stage rail at 448 × 40. The Version slot displays `Build <buildId>`.

## 4. States

| State | Display and behavior |
|---|---|
| Title | Studio display string and game title both use “FinalRun.” Minimum title dwell 800 ms, skippable after 250 ms. |
| Asset load | Start alongside title. Show integer floor(done ÷ total × 100) for known totals. Unknown work shows its stage label. A 30 s stalled-asset watchdog yields failure. |
| CEF load | Show “Loading interface” until `ready`. Allow 15 s per attempt. Native fallback retains Retry and Quit if browser startup fails. |
| Connecting | Always attempt the configured endpoint at boot, respecting `--connect host:port`. Show “Connecting to server” and indeterminate progress, with a 12 s timeout per attempt. |
| Ready | Known work reaches 100%. Wait out remaining title dwell unless skipped. Hand control to the existing authorized Motel transfer when all required gates pass. If map-load RPC arrives early, Main retains its pending work until UI readiness and title dwell complete, within the server transfer timeout. |
| Failure | Mark current stage Failed, show a readable reason and Retry. Quit remains available. A failed connection never unlocks gameplay. |
| Retry disabled | Lock repeated Retry until the new attempt starts or fails. Retry the failed stage and refresh its watchdog. |
| Build ID | Read `ProjectSettings` key `application/config/version`. Show that string in the Version slot, falling back to “dev” when empty. |

## 5. Interactions

Click Retry or Quit when offered. Enter skips the title only after the 250 ms threshold, consuming the press. During an active load only the eligible skip and OS window close remain available. On failure focus Retry, then Quit. Enter activates the focused action. Escape dismisses a subdialog. The native fallback offers the same recovery actions while CEF is unavailable. Gamepad later.

## 6. Data

Read `boot` → `BootView.phase`, `buildId`, `progress`, `canSkipTitle`, `error` and `canRetry`. Send `boot.skip`, `boot.retry` and `app.quit`. Observe `route` from Godot. Browser `ready` supplies the CEF readiness gate. Main resolves the configured endpoint and override locally.

## 7. Godot side

[Main.gd](../../main/Main.gd) owns startup, ENet connection callbacks and the configured endpoint. [Hud.gd](../../ui/hud/Hud.gd) owns browser readiness and page routing. **NEW** Main's Boot coordinator reads the build ID from `ProjectSettings`, resolves `--connect host:port` in all builds, and supplies progress, watchdog and retry state. Native fallback survives a CEF load failure.

## 8. Accessibility

Use body ≥14 px and version ≥11 px. Ensure ≥4.5:1 contrast. Focus ring surrounds the active button and survives mode changes. Announce stage changes politely and terminal errors once. Keep percentage updates silent between 10% steps. Completed, active, pending and failed stages include readable labels. Reduced motion keeps pending text static.

## 9. Decisions

1. Decided 2026-11-27: Use 800 ms title dwell, 250 ms skip threshold, studio string “FinalRun,” and `application/config/version` as build ID with “dev” fallback.
2. Decided 2026-11-27: Connect to the configured endpoint at boot, using 127.0.0.1:7777 in development. `--connect host:port` overrides it in every build.
3. Decided 2026-11-27: Use the approved 30 s asset, 15 s CEF and 12 s connection watchdogs, with native Retry/Quit recovery.
