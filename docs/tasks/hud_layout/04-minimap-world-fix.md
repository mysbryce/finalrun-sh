# hud_layout 04: fix the empty minimap (wrong World3D)

## Failing behavior (seen in a windowed client)
The minimap rect shows only the default grey clear color: the minimap camera renders an empty world.

## Cause
`features/instance/Instance.gd` sets `own_world_3d = true` on each instance SubViewport. For such a viewport `Viewport.world_3d` returns `null` (the property is only the explicitly assigned world), so `ui/hud/Minimap.gd` assigns `null` and its SubViewport falls back to the root's empty world. `Node3D.get_world_3d()` returns the world the node really lives in (the code base already uses it, e.g. `features/player/PlayerService.gd` line 303).

## Files
- modify: `ui/hud/Minimap.gd`
- modify: `AGENTS.md`

## Steps
1. `ui/hud/Minimap.gd` `_process`: replace `var world := _target.get_viewport().world_3d` with `var world := _target.get_world_3d()`. No other change.
2. `AGENTS.md`, end of "Lessons learned": add the line
   `- Instance SubViewports use own_world_3d, so Viewport.world_3d is null there. Get a node's world with Node3D.get_world_3d() (or Viewport.find_world_3d()).`

## Do not
- No other changes. Do not run git.

## Done when
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: the changed line and the last line of the test output.
