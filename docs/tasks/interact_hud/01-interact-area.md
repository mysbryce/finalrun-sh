# interact_hud 01: InteractArea component (client-side nearest interactable)

Roadmap: Phase 2, "Interact system (`lib/components/InteractArea`)". This card adds only the reusable component and its pure rule. Card 02 attaches it to lootables and adds the server RPC; card 04 shows the prompt.

## Context (already true, do not change)
- `lib/` holds reusable code with no feature imports (`docs/CONVENTIONS.md`). `lib/components/ChannelTimer.gd` is the existing component; follow its style (class_name, `##` doc comment under `extends`).
- No magic numbers: the interact range constant already exists: `GameConst.INTERACT_RANGE` (2.5 m) in `lib/constants/GameConst.gd`.
- Tests extend `TestCase` and use `assert_true`, `assert_eq` (see `tests/features/party/test_party_roles.gd`). `tests/run_tests.gd` auto-discovers `tests/**/test_*.gd`.

## Files
- create: `lib/components/InteractArea.gd`
- create: `tests/lib/components/test_interact_area.gd`

## Steps
1. Create `lib/components/InteractArea.gd`:
   ```gdscript
   class_name InteractArea
   extends Node3D
   ## Marks its parent as interactable. Clients use `nearest()` to pick the
   ## prompt target; the server always re-checks range itself. A hidden
   ## InteractArea (or one under a hidden parent) is ignored.

   const GROUP := &"interact_areas"

   ## Prompt text shown by the HUD, e.g. "E lockpick | V smash".
   @export var prompt: String = "Interact"
   ```
   - `func _enter_tree() -> void:` call `add_to_group(GROUP)`.
   - Pure static rule:
     ```gdscript
     ## Index of the closest position within max_range (inclusive), or -1.
     static func pick_nearest(from_pos: Vector3, positions: Array, max_range: float) -> int:
     ```
     Loop over `positions` (each a `Vector3`), track the smallest `from_pos.distance_to(p)` that is `<= max_range`, return its index. Ties keep the first index. Empty array returns -1.
   - Scene helper:
     ```gdscript
     ## Closest visible InteractArea in the same World3D as `from`, or null.
     static func nearest(from: Node3D, max_range: float) -> InteractArea:
     ```
     1. Return null if `from` is null, not valid, or not inside the tree.
     2. Build two arrays: `areas: Array[InteractArea]` and `positions: Array` from `from.get_tree().get_nodes_in_group(GROUP)`. Skip a node unless it is an `InteractArea`, `is_inside_tree()`, `is_visible_in_tree()`, and `get_world_3d() == from.get_world_3d()`.
     3. `var index := pick_nearest(from.global_position, positions, max_range)`; return `areas[index]` or null when -1.
2. Create `tests/lib/components/test_interact_area.gd` (`extends TestCase`):
   - `test_pick_nearest_empty`: `InteractArea.pick_nearest(Vector3.ZERO, [], 2.5) == -1`.
   - `test_pick_nearest_out_of_range`: positions `[Vector3(3, 0, 0)]`, range 2.5 gives -1.
   - `test_pick_nearest_edge_inclusive`: positions `[Vector3(2.5, 0, 0)]`, range 2.5 gives 0.
   - `test_pick_nearest_closest`: positions `[Vector3(2, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1.5)]`, range 2.5 gives 1.
   - `test_pick_nearest_tie_keeps_first`: positions `[Vector3(1, 0, 0), Vector3(-1, 0, 0)]`, range 2.5 gives 0.

## Do not
- Do not attach the component to any scene yet. Do not touch any file outside the list. Do not run git.

## Done when
- `godot_console --headless --path . --import` shows no script or parse errors (`.NET Sdk not found`, certificate and `user://` lines are harmless noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files changed, the last 3 lines of the test output, any step you could not do and why.
