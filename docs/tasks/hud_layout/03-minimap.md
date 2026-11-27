# hud_layout 03: minimap (Godot draws the map under the web page)

Design: `docs/design/HUD_LAYOUT.md`, zone "Top-left box". The page (`ui/web/src/features/hud/layout.ts` `MINIMAP = { left: 24, top: 40, width: 200, height: 170 }`) draws only a frame and the player arrow in that rect and leaves it transparent. Godot renders a north-up, top-down orthographic view of the player's world into the same rect, under the browser.

## Context (already true)
- `ui/hud/Hud.gd` (`class_name Hud extends CanvasLayer`): `_ready()` returns early unless `can_use_browser()`, then creates the full-screen `CefTexture` child `_browser`. `set_player(player: Node3D)` stores `_player`.
- Children of a CanvasLayer draw in tree order: a node added before `_browser` draws under the page.
- Each client instance is a `SubViewport` with its own `World3D`; `player.get_viewport().world_3d` is the world to show.
- North = world -Z (same as `Hud.heading_from_yaw`). A Camera3D rotated `-90°` around X looks straight down with screen-up = -Z.
- Tests extend `TestCase`; free nodes before asserting.

## Files
- modify: `lib/constants/GameConst.gd`
- create: `ui/hud/Minimap.gd`
- modify: `ui/hud/Hud.gd`
- create: `tests/ui/hud/test_minimap.gd`

## Steps
1. `GameConst.gd` `# HUD` block, add:
   ```gdscript
   const HUD_MINIMAP_RECT := Rect2(24, 40, 200, 170)  # px; must match ui/web/src/features/hud/layout.ts MINIMAP
   const HUD_MINIMAP_WORLD_SIZE: float = 60.0         # metres shown top to bottom
   const HUD_MINIMAP_HEIGHT: float = 80.0             # camera height above the player
   ```
2. Create `ui/hud/Minimap.gd`: `class_name Minimap extends TextureRect`, doc comment "North-up top-down view of the followed node's world, drawn in HUD_MINIMAP_RECT under the web page (which draws the frame and arrow)."
   - `static func camera_position(target: Vector3) -> Vector3`: `Vector3(target.x, target.y + GameConst.HUD_MINIMAP_HEIGHT, target.z)`.
   - vars `_viewport: SubViewport = null`, `_camera: Camera3D = null`, `_target: Node3D = null`.
   - `_ready()`:
     ```gdscript
     position = GameConst.HUD_MINIMAP_RECT.position
     size = GameConst.HUD_MINIMAP_RECT.size
     mouse_filter = Control.MOUSE_FILTER_IGNORE
     expand_mode = TextureRect.EXPAND_IGNORE_SIZE
     stretch_mode = TextureRect.STRETCH_SCALE
     _viewport = SubViewport.new()
     _viewport.size = Vector2i(GameConst.HUD_MINIMAP_RECT.size)
     _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
     _camera = Camera3D.new()
     _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
     _camera.size = GameConst.HUD_MINIMAP_WORLD_SIZE
     _camera.near = 1.0
     _camera.far = GameConst.HUD_MINIMAP_HEIGHT + 50.0
     _camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
     _viewport.add_child(_camera)
     add_child(_viewport)
     texture = _viewport.get_texture()
     visible = false
     ```
   - `func follow(target: Node3D) -> void`: `_target = target`.
   - `_process(_delta)`: if `_target == null or not is_instance_valid(_target) or not _target.is_inside_tree()`: `visible = false`, return. Else: `var world := _target.get_viewport().world_3d`; if `_viewport.world_3d != world`: `_viewport.world_3d = world`; `_camera.current = true`; `_camera.global_position = camera_position(_target.global_position)`; `visible = true`.
3. `Hud.gd`:
   - Add `var _minimap: Minimap = null`.
   - In `_ready()`, after the `can_use_browser()` early return and BEFORE `_browser` is created: `_minimap = Minimap.new()`, `_minimap.name = "Minimap"`, `add_child(_minimap)`.
   - In `set_player(player)`, after storing it: `if _minimap != null: _minimap.follow(player)`.
4. `tests/ui/hud/test_minimap.gd` (`extends TestCase`):
   - `test_camera_position`: `Minimap.camera_position(Vector3(3, 1, -4)) == Vector3(3, 1 + GameConst.HUD_MINIMAP_HEIGHT, -4)`.
   - `test_minimap_rect_and_hidden_without_target`: `var map := Minimap.new()`; `(Engine.get_main_loop() as SceneTree).root.add_child(map)`; read `map.position`, `map.size`, `map.visible`, and `map.get_child_count()` into locals; `map.free()`; assert position `== GameConst.HUD_MINIMAP_RECT.position`, size `== GameConst.HUD_MINIMAP_RECT.size`, visible false, child count 1 (the SubViewport).

## Do not
- Do not touch `ui/web/`, `ui/dist/`, `main/`, or server code. No map icons yet. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate, `user://` and `[Godot CEF]` lines are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
