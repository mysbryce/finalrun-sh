# appearance 02: CC0 base character (Kenney Mini Characters) in the CharacterRig, with idle/walk/sprint/die

Roadmap Phase 2: "Base character: CC0 low-poly modular humanoid + animations, male/female on one skeleton". The asset is already in the repo (supervisor copied it, credits in `assets/CREDITS.md`):
- `assets/characters/kenney_mini_characters/character-male-a.glb`, `character-female-a.glb` (CC0, Kenney Mini Characters 2.0), texture `Textures/colormap.png` (the GLBs reference it by relative URI).
- Both GLBs share one 7-joint skeleton: nodes `root`, `leg-left`, `leg-right`, `torso`, `arm-left`, `arm-right`, `head`, meshes `body-mesh`, `head-mesh`.
- Animations in both: `static, idle, walk, sprint, jump, fall, crouch, sit, drive, die, pick-up, emote-yes, emote-no, holding-right, holding-left, holding-both, holding-right-shoot, holding-left-shoot, holding-both-shoot, attack-melee-right, attack-melee-left, attack-kick-right, attack-kick-left, interact-right, interact-left, wheelchair-*`.

Godot only: do not touch `ui/` or `docs/ui-design/` (pending work elsewhere).

## Rules
- `lib/` never imports `features/`. No magic numbers in features: new numbers go in `GameConst.gd`.
- The rig is visual only: it never changes gameplay state; it reads replicated values (`role`, `life_state`, position) that already exist on `Player`.
- Tests extend `TestCase`; headless (`--headless`) must not crash when models load.

## Context (read first)
- `features/player/CharacterRig.gd` (from card 01): builds a placeholder capsule `Body` + one `Node3D` per slot in `GameConst.APPEARANCE_SLOTS`; `apply(appearance)`, `set_masked(masked)`; children built lazily by `_ensure_built()` because `apply` can run before the node is in the tree.
- `features/player/Player.gd`: `apply_appearance(data)`, `role` and `life_state` setters (replicated), `sync_position` (server snapshot), client interpolation in `_physics_process`/`_process` (read the file to find where the visual position/velocity is known on clients and on the server).
- `PlayerRoleController.LifeState` (`ALIVE`, `DOWNED`, `DEAD`, ...: read the enum).
- Collision capsule: r 0.4, h 1.8, centred at y 0.9; the rig origin is at the feet.

## Steps
1. Import check: run `godot_console --headless --path . --import` once so the GLBs and the texture get `.import` files. Confirm `res://assets/characters/kenney_mini_characters/character-male-a.glb` loads as a `PackedScene` and contains an `AnimationPlayer` with the animations above (write a throwaway check with `-s` in the session temp dir, not in the repo). Measure the model's height (merged AABB of its `MeshInstance3D`s in the rest pose) and report it.
2. `GameConst.gd` `# Appearance` block: `const BODY_MODELS: Dictionary = {"male": "res://assets/characters/kenney_mini_characters/character-male-a.glb", "female": "res://assets/characters/kenney_mini_characters/character-female-a.glb"}`, `const CHARACTER_HEIGHT: float = 1.8` (target visual height in metres), `const ANIM_WALK_SPEED: float = 0.5` (m/s; below this play `idle`), `const ANIM_SPRINT_SPEED: float = 4.5` (m/s; at or above this play `sprint`; read the player move speed constant in `GameConst.gd` and set these to about 10% and 90% of it, report the values), `const ANIM_BLEND_TIME: float = 0.15`.
3. `CharacterRig.gd`:
   - Replace the placeholder capsule `Body` with the model: on `apply`, when the body type changes (or first time), free the old model and instantiate `load(BODY_MODELS[body_type])` (fallback `"male"`) as child `Model`; uniformly scale it so its measured height equals `CHARACTER_HEIGHT` (compute the scale once from the AABB at load, not a hard-coded number). If loading fails (missing file), fall back to the old placeholder capsule so headless tests and broken assets never crash.
   - Find the model's `AnimationPlayer` (`find_children("*", "AnimationPlayer", true, false)`); set `idle`, `walk`, `sprint` to loop.
   - `func set_motion(speed: float) -> void`: `idle` below `ANIM_WALK_SPEED`, `walk` below `ANIM_SPRINT_SPEED`, else `sprint`; only call `play(name, ANIM_BLEND_TIME)` when the target animation changes. Ignored while a life pose is active (next bullet).
   - `func set_life_state(state: int) -> void`: `DOWNED` -> play `sit` (placeholder downed pose, hold last frame), `DEAD` -> play `die` (hold last frame), `ALIVE` -> back to motion animations. Use the real enum values from `PlayerRoleController.LifeState`.
   - Slot cosmetics and `set_masked` keep working as today (the primitive meshes stay at their offsets; bone attachment comes with real cosmetics later: add a `# ponytail:` comment saying so).
4. `Player.gd`:
   - In the `life_state` setter (guarded with `is_node_ready()` like the role setter) and in `_ready`, call `$Rig.set_life_state(life_state)`.
   - Every frame (server and clients), feed `$Rig.set_motion(horizontal_speed)` where `horizontal_speed` is the length of the XZ change of the player's visual position per second (keep the last visual position in a local var; on clients that is the interpolated position, on the server the body position). Do not add networking.
   - The rig faces the movement/yaw direction the player already uses for its visual rotation (if the player node itself rotates by `sync_yaw`, nothing to do; check and report). Kenney models face +Z; if the player forward is -Z, rotate `Model` 180° around Y inside the rig.
5. Tests (`tests/features/player/test_character_rig.gd`, extend the existing file):
   - After `apply(AppearanceData.default_for(1))` (male) the rig has a `Model` child with an `AnimationPlayer` that has `idle`, `walk`, `sprint`, `die`, `sit`; after applying `default_for(2)` (female) the `Model` changed (different scene file path) and there is exactly one `Model`.
   - `set_motion(0.0)` -> current animation `idle`; `set_motion(ANIM_SPRINT_SPEED)` -> `sprint`; `set_life_state(DEAD)` -> `die` and a following `set_motion(0.0)` keeps `die`; `set_life_state(ALIVE)` then `set_motion(0.0)` -> `idle`.
   - The merged AABB height of `Model` is within 0.05 of `CHARACTER_HEIGHT`.
   - Existing rig tests (slots, mask) still pass. If the AnimationPlayer needs the tree to play, add the rig to the test's scene tree and free it afterwards.
6. `docs/ROADMAP.md`: tick the Base character line `[x]` and append ` (Kenney Mini Characters, CC0; see assets/CREDITS.md)`.
7. Run Done-when, then a smoke check: `pwsh tools/smoke_local.ps1 -Clients 2`, wait 15 s, confirm both client logs have no `SCRIPT ERROR` / `ERROR:` lines from `CharacterRig` or `Player`, then `pwsh tools/smoke_local.ps1 -Stop` (never pipe the script's output).

## Do not
- No new assets or downloads, no other model variants. No changes to movement, networking or gameplay rules. No `ui/` or `docs/ui-design/`. Do not run git.

## Done when
- Import shows no script or parse errors (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Smoke check in step 7 clean.
- Final answer: measured model height and scale, the ANIM speed values and the move speed they came from, model facing fix (if any), files changed/created (including generated `.import` files), last 3 test lines, smoke check result, any step you could not do and why.
