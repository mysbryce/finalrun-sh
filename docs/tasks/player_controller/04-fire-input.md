# player_controller 04: client fire input (left mouse button)

Roadmap: Phase 2, hitscan weapons, client side. Needs card 03 (`ServerManager.request_fire(aim: Vector3)`, `GameConst.FIRE_INTERVAL_MS`).

## Context (already true, do not change)
- `features/player/PlayerCamera.gd`: client-only camera. Children: `Pitch` -> `Arm` (`SpringArm3D`) -> `Camera` (`Camera3D`, stored in `_camera`). Left click while the mouse is visible recaptures it.
- `features/player/Player.gd`: `_input_enabled` is true only on the owning client; `_camera: PlayerCamera` exists only then.
- Features must not reference the `ServerManager` autoload by name (dependency direction is autoload -> features). `Player.gd` already reaches it with `get_node_or_null("/root/ServerManager")` plus `has_method(...)`; use the same pattern.
- Godot delivers `_unhandled_input` to children before parents, so `PlayerCamera` sees a click before `Player` does.

## Files
- modify: `features/player/PlayerCamera.gd`
- modify: `features/player/Player.gd`
- modify: `tests/features/player/test_player_motion.gd`

## Steps
1. `PlayerCamera.gd`:
   - Add `func get_aim_direction() -> Vector3`: return `Vector3.ZERO` if `_camera` is null or invalid, else `-_camera.global_transform.basis.z`.
   - In `_unhandled_input`, in the branch that recaptures the mouse on left click, call `get_viewport().set_input_as_handled()` right after setting `MOUSE_MODE_CAPTURED`. This stops the recapture click from also firing a shot.
2. `Player.gd`:
   - Add `var _last_fire_local_ms: int = 0`.
   - Add pure static helper (next to the other static helpers):
     ```gdscript
     ## Client-side fire gate; the server enforces the same interval again.
     static func can_fire_locally(now_ms: int, last_fire_ms: int) -> bool:
         return now_ms - last_fire_ms >= GameConst.FIRE_INTERVAL_MS
     ```
   - Add `_unhandled_input(event: InputEvent) -> void`:
     1. Return unless `_input_enabled`.
     2. Return unless `event` is an `InputEventMouseButton`, `pressed`, `button_index == MOUSE_BUTTON_LEFT`.
     3. Return unless `Input.mouse_mode == Input.MOUSE_MODE_CAPTURED` and `_camera` is valid.
     4. `var now_ms: int = Time.get_ticks_msec()`; return unless `can_fire_locally(now_ms, _last_fire_local_ms)`; then `_last_fire_local_ms = now_ms`.
     5. `var aim := _camera.get_aim_direction()`; return if `aim == Vector3.ZERO`.
     6. `var server_manager := get_node_or_null("/root/ServerManager")`; if not null and `server_manager.has_method("request_fire")`: `server_manager.request_fire(aim)`.
3. `tests/features/player/test_player_motion.gd`, add:
   - `test_can_fire_locally_after_interval`: `PlayerCharacter.can_fire_locally(GameConst.FIRE_INTERVAL_MS, 0)` is true.
   - `test_can_fire_locally_blocked`: `PlayerCharacter.can_fire_locally(GameConst.FIRE_INTERVAL_MS - 1, 0)` is false.

## Do not
- Do not touch `ServerManager.gd`, `PlayerService.gd`, or `Main.gd`. No muzzle flash or VFX. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
