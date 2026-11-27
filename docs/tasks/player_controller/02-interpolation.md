# player_controller 02: smooth replicated movement (client interpolation)

Roadmap: Phase 2, "interpolation". Builds on card 01 (camera, facing).

## Context (already true, do not change)
- The server owns movement in `Player._server_physics()`. Clients never simulate.
- `features/player/Player.tscn` replicates `.:position` and `.:rotation` directly (`replication_mode = 1`, `spawn = true`), so remote bodies jump at each sync packet.
- Other code reads `position` / `global_position` on both peers (LOS raycast, nearest target, smoke hook in `ServerManager._tick_smoke`). The server's `position` stays the real one; the client's `position` becomes the smoothed one.

## Files
- modify: `lib/constants/GameConst.gd`
- modify: `features/player/Player.gd`
- modify: `features/player/Player.tscn`
- modify: `tests/features/player/test_player_motion.gd`

## Steps
1. `lib/constants/GameConst.gd`, next to the other `PLAYER_*` constants:
   ```gdscript
   const PLAYER_SYNC_INTERVAL: float = 0.05   # seconds between position snapshots (20 Hz)
   const PLAYER_INTERP_RATE: float = 15.0     # exponential smoothing rate per second
   const PLAYER_SNAP_DISTANCE: float = 3.0    # metres; larger gaps teleport instead of sliding
   ```
2. `features/player/Player.gd`, new replicated snapshot properties under `downed_deadline_ms`:
   ```gdscript
   ## Server-written snapshot of the authoritative transform. Clients smooth toward it.
   @export var sync_position: Vector3 = Vector3.ZERO
   @export var sync_yaw: float = 0.0
   ```
   Plain properties, no setters. Add `var _has_snapshot: bool = false`.
3. `Player.gd` pure static helpers (next to the card 01 helpers):
   ```gdscript
   static func interp_weight(delta: float) -> float:
       return 1.0 - exp(-GameConst.PLAYER_INTERP_RATE * delta)

   ## Next client position: snap when far (spawn, teleport), otherwise slide.
   static func smoothed_position(current: Vector3, target: Vector3, delta: float) -> Vector3:
       if current.distance_to(target) > GameConst.PLAYER_SNAP_DISTANCE:
           return target
       return current.lerp(target, interp_weight(delta))
   ```
4. `Player.gd` server side:
   - At the end of `_server_physics()`, after `move_and_slide()`: `sync_position = position` and `sync_yaw = rotation.y`.
   - At the end of `setup_server()`, after the spawn position is applied: `sync_position = position` and `sync_yaw = rotation.y` (spawn state must carry the spawn point).
5. `Player.gd` client side, new `_process(delta)`:
   - Return if `not multiplayer.has_multiplayer_peer()` or `multiplayer.is_server()`.
   - If not `_has_snapshot`: `position = sync_position`, `rotation.y = sync_yaw`, `_has_snapshot = true`, return.
   - Else: `position = smoothed_position(position, sync_position, delta)`; `rotation.y = lerp_angle(rotation.y, sync_yaw, interp_weight(delta))`.
6. `Player.gd` `_ready()`: after the synchronizer is found, set `sync.replication_interval = GameConst.PLAYER_SYNC_INTERVAL`.
7. `features/player/Player.tscn` `SceneReplicationConfig_player`:
   - `properties/2/path` changes from `NodePath(".:position")` to `NodePath(".:sync_position")`.
   - `properties/3/path` changes from `NodePath(".:rotation")` to `NodePath(".:sync_yaw")`.
   - Keep `spawn = true` and `replication_mode = 1` for both. Change nothing else in the file.
8. `tests/features/player/test_player_motion.gd`, add:
   - `test_smoothed_position_slides_partway`: from `Vector3.ZERO` to `Vector3(1, 0, 0)` with delta `0.016` gives an x > 0.0 and < 1.0.
   - `test_smoothed_position_snaps_when_far`: from `Vector3.ZERO` to `Vector3(10, 0, 0)` returns exactly `Vector3(10, 0, 0)`.
   - `test_interp_weight_bounds`: `interp_weight(0.0)` approx `0.0`; `interp_weight(10.0)` approx `1.0`.
   - `test_player_scene_replicates_snapshot`: load `res://features/player/Player.tscn`, instantiate, get `MultiplayerSynchronizer`, read `replication_config.get_properties()`; assert it contains `NodePath(".:sync_position")` and `NodePath(".:sync_yaw")` and does not contain `NodePath(".:position")`. Free the node before asserting (store the results in locals first).

## Do not
- Do not move the body on the client with `move_and_slide()` or add prediction.
- Do not change server code outside `Player.gd`. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
