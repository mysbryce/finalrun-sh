# ui_impl 16: the browser stops eating keys; the minimap hides with the HUD (Godot)

Found in the step 14 desktop smoke:
- After any click into the page (Settings, Pause, inventory), Godot stops seeing keys: Tab no longer opens the inventory, Esc no longer opens Pause, and the rebind dialog never captures a key (mouse buttons still capture). The CEF node (`CefTexture`, native GDExtension) overrides `_input`, forwards keys to the page and marks them handled once the page has been clicked. `_input` runs in reverse tree order, so the browser (a child of Hud) sees keys before `Main._input`, `Main._unhandled_input` and `Player._unhandled_input`. Design rule (AGENTS.md): keys never reach the page in game; the page has no text fields.
- The Godot minimap (`Minimap`, a Hud child under the browser) stays visible on routes where the web page hides the HUD (`/inventory`, `/search`, `/death`, ...). Web rule: `ui/web/src/app/showsHud.ts`.

Read first: `ui/hud/Hud.gd` (`_ready`, `_navigate`, `_minimap`), `ui/web/src/app/showsHud.ts`, `tests/ui/hud/test_hud.gd`.

## Decisions for this card (supervisor)
- Hud: `const HUD_HIDDEN_ROUTES := ["/inventory", "/search", "/splash", "/lobby", "/death", "/arrest", "/transfer"]` and `static func shows_hud(route: String) -> bool` returning `not HUD_HIDDEN_ROUTES.has(route) and not route.begins_with("/settings")`. Doc comment: mirror of `ui/web/src/app/showsHud.ts`, keep both lists equal.
- `_navigate(to)`: after `_route = to`, `if _minimap != null: _minimap.visible = shows_hud(to)`.
- Hud: `static func mute_keys(node: Node) -> void` calls `set_process_input(false)`, `set_process_unhandled_input(false)`, `set_process_unhandled_key_input(false)`, `set_process_shortcut_input(false)` on `node`. Doc comment: CefTexture's native `_input` forwards keys to the page and marks them handled after a page click, so Main and Player stop seeing Tab, Esc and rebind keys; the page gets no keys in game (no text fields); mouse still reaches it through `_gui_input`.
- `_ready`: call `mute_keys(_browser)` directly after `add_child(_browser)` (the node's READY has run by then, so the flags stick).

## Rules
- `ui/` never references `ServerManager`. Tests extend `TestCase`, mirror the source tree, no setup/teardown hooks. Free every node a test creates.

## Files
- modify: `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`

## Steps
1. `HUD_HIDDEN_ROUTES`, `shows_hud`, the `_navigate` line.
2. `mute_keys` and the `_ready` call.
3. Tests in `test_hud.gd`:
   - `test_shows_hud_routes`: true for `/` and `/pause`; false for `/inventory`, `/search`, `/splash`, `/lobby`, `/death`, `/arrest`, `/transfer`, `/settings/controls`.
   - `test_mute_keys`: a `Control.new()` with all four `set_process_*` set to true; after `Hud.mute_keys(node)` assert `is_processing_input()`, `is_processing_unhandled_input()`, `is_processing_unhandled_key_input()`, `is_processing_shortcut_input()` are all false; free the node.
4. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`.

## Do not
- No web changes. Do not edit `docs/` or `ui/dist/`. Do not run git. Do not start the smoke script (the supervisor runs it).

## Done when
- Import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`.
- Final answer: files changed, last 3 Godot test lines, anything you could not do and why.
