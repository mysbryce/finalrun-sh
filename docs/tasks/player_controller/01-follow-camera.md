# player_controller 01: third-person follow camera, camera-relative movement, server-side facing

Roadmap: Phase 2, "Player controller + camera". Card 02 adds interpolation; do not start it.

## Context (already true, do not change)
- `features/player/Player.gd` (`PlayerCharacter`): the owning client reads WASD in `_read_input()` and sends `server_request_move(input: Vector2)` (x = world X, y = world Z). The server moves the body in `_server_physics()`. `_input_enabled` is true only on the owning client.
- `features/instance/Instance.gd` `_install_client_camera()` adds a fixed overview camera on clients. Keep it; it stays the fallback when no local player exists.
- Player collision layer is 2, world is layer 1.
- Node scripts may read `GameConst`. No magic numbers in `.gd` files.

## Files
- modify: `lib/constants/GameConst.gd`
- create: `features/player/PlayerCamera.gd`
- modify: `features/player/Player.gd`
- create: `tests/features/player/test_player_motion.gd`
- modify: `tests/run_tests.gd` (register the new test file the same way the others are registered)

## Steps
1. In `lib/constants/GameConst.gd`, add a `# Camera` block next to the other `PLAYER_*` constants:
   ```gdscript
   const CAMERA_PIVOT_HEIGHT: float = 1.6
   const CAMERA_DISTANCE: float = 4.5
   const CAMERA_MOUSE_SENSITIVITY: float = 0.003  # radians per pixel
   const CAMERA_PITCH_MIN: float = -1.2           # radians, looking down
   const CAMERA_PITCH_MAX: float = 0.6            # radians, looking up
   const PLAYER_TURN_SPEED: float = 12.0          # lerp_angle rate per second
   ```
2. Create `features/player/PlayerCamera.gd`:
   - `class_name PlayerCamera` / `extends Node3D`. Doc comment: client-only third-person camera for the local player.
   - `var target: Node3D = null`, `var _pitch: Node3D`, `var _arm: SpringArm3D`, `var _camera: Camera3D`.
   - `_ready()`:
     - `top_level = true` (yaw must not follow the body rotation).
     - Build children in code: `_pitch = Node3D.new()` named `Pitch`, child of self; `_arm = SpringArm3D.new()` named `Arm`, child of `_pitch`, `spring_length = GameConst.CAMERA_DISTANCE`, `collision_mask = 1`, `margin = 0.2`; `_camera = Camera3D.new()` named `Camera`, child of `_arm`, then `_camera.current = true`.
     - `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`.
   - `_process(_delta)`: if `target != null and is_instance_valid(target)`: `global_position = target.global_position + Vector3(0.0, GameConst.CAMERA_PIVOT_HEIGHT, 0.0)`.
   - `_unhandled_input(event)`:
     - `InputEventMouseMotion` while `Input.mouse_mode == Input.MOUSE_MODE_CAPTURED`: `rotation.y -= event.relative.x * GameConst.CAMERA_MOUSE_SENSITIVITY`; `_pitch.rotation.x = clampf(_pitch.rotation.x - event.relative.y * GameConst.CAMERA_MOUSE_SENSITIVITY, GameConst.CAMERA_PITCH_MIN, GameConst.CAMERA_PITCH_MAX)`.
     - `InputEventKey` pressed, not echo, `physical_keycode == KEY_ESCAPE`: `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE`.
     - `InputEventMouseButton` pressed with `button_index == MOUSE_BUTTON_LEFT` while the mouse is visible: capture it again.
   - `func get_yaw() -> float: return rotation.y`
   - `_exit_tree()`: `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE`.
3. In `features/player/Player.gd` add three pure static helpers (near the bottom, above `_now_ms`):
   ```gdscript
   ## Turns raw WASD (x = right, y = back) into a world XZ direction for a camera yaw.
   static func camera_relative_input(raw: Vector2, yaw: float) -> Vector2:
       return raw.limit_length(1.0).rotated(-yaw)

   ## Body yaw that faces a world-space move direction (Godot forward is -Z).
   static func facing_yaw(direction: Vector3) -> float:
       return atan2(-direction.x, -direction.z)
   ```
   and a third helper used by step 5:
   ```gdscript
   static func turn_toward(current_yaw: float, target_yaw: float, delta: float) -> float:
       return lerp_angle(current_yaw, target_yaw, clampf(GameConst.PLAYER_TURN_SPEED * delta, 0.0, 1.0))
   ```
4. In `Player.gd` camera ownership:
   - Add `var _camera: PlayerCamera = null`.
   - At the end of `_update_control_state()` (both branches: also the early-return branch) call a new `_sync_camera()`. Restructure the early return so `_sync_camera()` always runs last.
   - `_sync_camera()`: if `_input_enabled and _camera == null`: create `PlayerCamera.new()`, name it `PlayerCamera`, set `target = self`, `add_child.call_deferred(_camera)`. If `not _input_enabled and _camera != null`: `_camera.queue_free()`, `_camera = null`.
5. In `Player.gd`:
   - `_read_input()`: keep the key reading; replace the final `return Vector2(x, z).limit_length(1.0)` with: build `var raw := Vector2(x, z)`; if `_camera != null and is_instance_valid(_camera)` return `camera_relative_input(raw, _camera.get_yaw())`, else return `raw.limit_length(1.0)`.
   - `_server_physics(delta)`: after `direction` is computed and normalized, and before `move_and_slide()`: if `speed > 0.0 and direction.length_squared() > 0.0001`, set `rotation.y = turn_toward(rotation.y, facing_yaw(direction), delta)`. Rotation is already replicated.
6. Create `tests/features/player/test_player_motion.gd` in the same style as the other test files (extends the shared `TestCase`, same naming of test methods). Tests:
   - `test_camera_relative_forward_at_zero_yaw`: `PlayerCharacter.camera_relative_input(Vector2(0, -1), 0.0)` is approx `Vector2(0, -1)`.
   - `test_camera_relative_forward_at_quarter_turn`: yaw `PI / 2` turns W into approx `Vector2(-1, 0)`.
   - `test_camera_relative_right_at_quarter_turn`: yaw `PI / 2` turns D `Vector2(1, 0)` into approx `Vector2(0, -1)`.
   - `test_camera_relative_clamps_diagonal`: `Vector2(1, -1)` at yaw 0 has length approx 1.0.
   - `test_facing_yaw_forward`: `facing_yaw(Vector3(0, 0, -1))` approx `0.0`.
   - `test_facing_yaw_left`: `facing_yaw(Vector3(-1, 0, 0))` approx `PI / 2`.
   - `test_turn_toward_moves_partway`: `turn_toward(0.0, 1.0, 0.01)` is > 0.0 and < 1.0.
   - `test_turn_toward_large_delta_reaches_target`: `turn_toward(0.0, 1.0, 1.0)` approx `1.0`.
   Use an epsilon of `0.001` for approx checks.

## Do not
- Do not touch `Instance.gd`, the synchronizer config, or `Player.tscn`.
- Do not add client-side prediction or move the body on the client.
- Do not rename existing functions. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
