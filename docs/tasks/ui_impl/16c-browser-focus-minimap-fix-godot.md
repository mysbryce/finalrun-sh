# ui_impl 16c: fix card 16 (browser focus, minimap visibility) (Godot)

Card 16 did not fix either smoke bug. Runtime findings after card 16:
- Tab after a click into the inventory still does nothing. Cause, from the godot-cef source (`crates/gdcef/src/cef_texture/mod.rs` `on_ready`, `input_routing.rs`): CefTexture's `on_ready` calls `set_focus_mode(FocusMode::CLICK)`, which overwrites the `focus_mode = FOCUS_NONE` that `Hud._ready` sets before `add_child`. A page click then gives the browser Godot GUI focus; with GUI focus, the viewport's focus navigation consumes Tab (`ui_focus_next`), and the browser's `_input` forwards keys to the page and marks them handled (its `_input` returns early only when the GUI focus owner is outside the browser). Clicks do not need GUI focus (`browser_input_available` only checks the window focus).
- The minimap image stays visible on `/inventory`: `Minimap._process` sets `visible = true` every frame while it has a target, so the `_navigate` line from card 16 is overwritten one frame later.

Read first: `ui/hud/Hud.gd` (`_ready`, `mute_keys`, `_navigate`), `ui/hud/Minimap.gd`, `tests/ui/hud/test_hud.gd` (`test_mute_keys`), `tests/ui/hud/test_minimap.gd`.

## Decisions for this card (supervisor)
- Hud `_ready`: remove the `_browser.focus_mode = Control.FOCUS_NONE` line before `add_child`, and replace the `mute_keys(_browser)` call after `add_child(_browser)` with `_browser.focus_mode = Control.FOCUS_NONE` plus a comment: CefTexture's ready sets CLICK focus; a focused browser takes keys (Tab focus navigation and its own `_input`), so keys stop reaching Main. Delete `static func mute_keys` and `test_mute_keys`.
- Minimap: new `var shown: bool = true` with doc comment "False while the route hides the HUD (Hud._navigate)". In `_process`, the last line `visible = true` becomes `visible = shown`. The no-target branch stays `visible = false`.
- Hud `_navigate`: replace `_minimap.visible = shows_hud(to)` with `_minimap.shown = shows_hud(to)`.

## Rules
- `ui/` never references `ServerManager`. Tests extend `TestCase`, mirror the source tree, no setup/teardown hooks. Free every node a test creates; read values into locals before `free()`.

## Files
- modify: `ui/hud/Hud.gd`, `ui/hud/Minimap.gd`, `tests/ui/hud/test_hud.gd`, `tests/ui/hud/test_minimap.gd`

## Steps
1. Hud focus change and removal of `mute_keys` (+ its test).
2. Minimap `shown`, Hud `_navigate` line.
3. Test in `test_minimap.gd`, `test_minimap_shown_flag`: add a `Minimap` and a `Node3D` target to the scene root (`(Engine.get_main_loop() as SceneTree).root`), `map.follow(target)`; set `map.shown = false`, call `map._process(0.0)`, read `map.visible`; set `map.shown = true`, call `map._process(0.0)`, read `map.visible`; free both nodes; assert false then true.
4. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`.

## Do not
- No web changes. Do not edit `docs/` or `ui/dist/`. Do not run git. Do not start the smoke script.

## Done when
- Import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`.
- Final answer: files changed, last 3 Godot test lines, anything you could not do and why.
