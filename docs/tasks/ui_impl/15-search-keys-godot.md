# ui_impl 15: body-search keys while the search panel is open (Godot)

Design source: `docs/ui-design/04-hud.md` section 5 third paragraph ("Q or its binding and Escape close search. T takes the first active-session item only in supported developer builds."), `docs/ui-design/flow.md` `/search` row ("Q/bound close, Escape ..."). Today `Main._unhandled_input` drops every action except `bind_inventory` while a panel is open, so Q and T do nothing on `/search`, and both target the nearest player instead of the open search. Card 15b already made `bind_search_take` a debug shortcut in the schema (`"capability": "debug_shortcuts"`, `"unavailable": "hidden"`) and rebuilt `ui/dist/settings-schema.json`, which is the file Godot reads (`GameConst.SETTINGS_SCHEMA_PATH`). Read first: `main/Main.gd` (`_unhandled_input`, `_run_action` branches `bind_search_take` / `bind_search_close`, `_search_items`, the Controls print in `_start_client`), `ui/hud/Hud.gd` (`_search_target`, `is_search_open`, `request_search_close`), `ui/settings/SettingsService.gd` (doc comment on line 3), `tests/ui/settings/test_settings_service.gd` (the loop over debug-only bindings near line 238), `tests/ui/hud/test_hud.gd` (`test_open_and_close_search_headless`).

## Decisions for this card (supervisor)
- Hud: `func search_target() -> int` returns `_search_target`.
- `Main._unhandled_input`: directly before `if _hud != null and _hud.is_panel_open(): return`, add: `if _hud != null and _hud.is_search_open() and (action == "bind_search_close" or action == "bind_search_take"): _run_action(action); return`.
- `_run_action`:
  - `bind_search_close`: `if _hud.is_search_open(): _hud.request_search_close()`; otherwise do nothing (remove the nearest-player request: without an open search the server ignores it).
  - `bind_search_take`: return unless `_hud.is_search_open()`; target `_hud.search_target()`; the rest (first item of `_search_items[target]`, `request_search_take`, the "No items" print) stays.
- Controls print: `T take` becomes `T take (debug)`.
- `SettingsService.gd` line 3 doc comment: say the runtime schema is `res://ui/dist/settings-schema.json`, copied by the web build from `ui/web/public/settings-schema.json`.

## Rules
- `ui/` never references `ServerManager`; Main wires actions. Tests extend `TestCase`, mirror the source tree, no setup/teardown hooks.

## Files
- modify: `ui/hud/Hud.gd`, `main/Main.gd`, `ui/settings/SettingsService.gd` (comment only), `tests/ui/settings/test_settings_service.gd`, `tests/ui/hud/test_hud.gd`

## Steps
1. Hud `search_target()`.
2. Main input, `_run_action` changes and the Controls print.
3. SettingsService comment.
4. Tests: add `"bind_search_take"` to the debug-only binding loop in `test_settings_service.gd`; in `test_open_and_close_search_headless` assert `search_target()` is the target after open and 0 after close.
5. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`.

## Do not
- No web changes. Do not edit `docs/` or `ui/dist/`. Do not run git.

## Done when
- Import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`.
- Final answer: files changed, last 3 Godot test lines, anything you could not do and why.
