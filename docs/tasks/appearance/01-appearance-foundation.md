# appearance 01: AppearanceData, cosmetic data and a slot-based character rig (placeholder meshes)

Roadmap Phase 2: "Appearance foundation: `AppearanceData` Resource (body type, slot -> item id), synced once on spawn, modular character rig with swappable slots. Built now so later cosmetics are data only." The real CC0 character comes later; this card uses primitive placeholder meshes so the data path is real today. Godot only: do not touch `ui/` (another change is pending there) or `docs/ui-design/`.

## Rules (from docs/CONVENTIONS.md)
- `lib/` never imports `features/`, `maps/`, `ui/`. Data definitions are `Resource` subclasses in `lib/data/` with `.tres` files in `data/`. No magic numbers in features (constants in `GameConst.gd` or `.tres`).
- Networking: appearance travels in the spawn payload (public, replicated to visible peers). The server owns it; clients never send it in this card.
- Tests extend `TestCase`, mirror the source tree, and run from `tests/run_tests.gd` (check how it discovers files).

## Context (already true)
- `features/player/Player.tscn`: `CharacterBody3D` with `CollisionShape3D` (capsule r 0.4, h 1.8), `Mesh` (`MeshInstance3D`, `CapsuleMesh` + blue `StandardMaterial3D`), `PlayerRoleController`, `MultiplayerSynchronizer`. Check `Player.gd` for any reference to the `Mesh` node before removing it.
- `features/player/Player.gd`: `@export var role` setter calls `_role_controller.handle_replicated_role(old, new)` (runs on server and clients). Role enum: `PlayerRoleController.Role` (`CITIZEN`, `CRIMINAL`, `COP`).
- `features/instance/InstanceRegistry.gd` `spawn_player(peer_id, instance)` builds the spawn payload `{"peer_id", "instance_id"}` (comment: the payload is replicated to visible peers, so only public data).
- `features/player/PlayerService.gd` `spawn_node(data)` (~l.172) instantiates the scene on server and clients; disconnect cleanup erases `_states[peer_id]` (~l.136). `autoload/ServerManager.gd` ~l.60 wires `_instances.set_spawn_function(Callable(_players, "spawn_node"))`.

## Files
- create: `lib/data/AppearanceData.gd`, `lib/data/CosmeticData.gd`, `data/cosmetics/*.tres` (6 files, below), `features/player/CharacterRig.gd`
- modify: `lib/constants/GameConst.gd`, `features/player/Player.tscn`, `features/player/Player.gd`, `features/player/PlayerService.gd`, `features/instance/InstanceRegistry.gd`, `autoload/ServerManager.gd`
- create tests: `tests/lib/data/test_appearance_data.gd`, `tests/features/player/test_character_rig.gd`
- modify: `docs/ROADMAP.md` (tick the item, see step 9)

## Steps
1. `GameConst.gd` (new block `# Appearance`): `const APPEARANCE_SLOTS: PackedStringArray = ["hair", "top", "bottom", "shoes", "hat", "mask"]`, `const BODY_TYPES: PackedStringArray = ["male", "female"]`, `const COSMETICS_DIR: String = "res://data/cosmetics/"`.
2. `lib/data/CosmeticData.gd`: `class_name CosmeticData extends Resource`; `@export var id: String`, `@export var slot: String`, `@export var mesh: Mesh`, `@export var color: Color = Color.WHITE`, `@export var offset: Vector3`. Doc comment: pure visual, no stats; later the mesh is skinned to the shared skeleton.
3. `lib/data/AppearanceData.gd`: `class_name AppearanceData extends Resource`; `@export var body_type: String = "male"`, `@export var slots: Dictionary = {}` (slot -> cosmetic id).
   - `func to_dict() -> Dictionary` -> `{"body_type": body_type, "slots": slots.duplicate()}`.
   - `static func from_dict(data: Variant) -> AppearanceData`: never fails; non-Dictionary -> default; `body_type` not in `GameConst.BODY_TYPES` -> `"male"`; keep only `slots` entries whose key is in `GameConst.APPEARANCE_SLOTS` and whose value is a non-empty `String` (cap ids at 64 chars, drop longer).
   - `static func default_for(peer_id: int) -> AppearanceData`: deterministic variety for tests and smoke runs: `body_type = BODY_TYPES[peer_id % 2]`; `slots = {"hair": ["hair_short", "hair_long"][peer_id % 2], "top": ["top_tee", "top_jacket"][(peer_id / 2) % 2], "mask": "mask_basic"}` (use `absi(peer_id)` so negative ids work).
4. `data/cosmetics/` six `.tres` files (`CosmeticData`, placeholder primitive meshes as sub-resources, `offset` relative to the player origin at the feet; body is 1.8 m tall):
   `hair_short` (hair, `SphereMesh` r 0.2 h 0.25, dark brown, offset (0, 1.72, 0)), `hair_long` (hair, `CapsuleMesh` r 0.2 h 0.6, black, (0, 1.6, -0.05)), `top_tee` (top, `CylinderMesh` r 0.42 h 0.6, white, (0, 1.2, 0)), `top_jacket` (top, `CylinderMesh` r 0.44 h 0.7, olive, (0, 1.15, 0)), `mask_basic` (mask, `BoxMesh` 0.3 x 0.2 x 0.1, black, (0, 1.6, 0.2)), `hat_cap` (hat, `CylinderMesh` r 0.22 h 0.1, red, (0, 1.85, 0)).
5. `features/player/CharacterRig.gd`: `class_name CharacterRig extends Node3D`.
   - Builds one child `MeshInstance3D` named `Body` (capsule r 0.4 h 1.8 at y 0.9; male `Color(0.25, 0.68, 0.95)`, female `Color(0.95, 0.45, 0.6)`) and one child `Node3D` per slot in `APPEARANCE_SLOTS` named after the slot.
   - `func apply(appearance: AppearanceData) -> void`: sets the body colour; for each slot clears the slot node's children, then if the appearance has an id for it, loads `COSMETICS_DIR + id + ".tres"` (skip silently with `push_warning` when missing or when its `slot` does not match), adds a `MeshInstance3D` with the mesh, a `StandardMaterial3D` of `color`, at `offset`.
   - `func set_masked(masked: bool) -> void`: shows the `mask` slot node only when `masked`.
   - Keep a local `_appearance` so `apply` can be called again (idempotent).
6. `Player.tscn` / `Player.gd`: replace the `Mesh` node with a `Rig` node (`Node3D` + `CharacterRig.gd`), same transform the old mesh had offset to (the old capsule was centred; the rig's body sits at y 0.9 so match the collision shape: check the CollisionShape3D position and place `Rig` so the body capsule lines up with it). `Player.gd`: `var appearance: AppearanceData = AppearanceData.new()`; `func apply_appearance(data: Variant) -> void` (from_dict, store, `$Rig.apply`, then `$Rig.set_masked(role == PlayerRoleController.Role.CRIMINAL)`); in the `role` setter also call `$Rig.set_masked(...)` when the node is ready (guard `is_node_ready()` / null).
7. Server wiring:
   - `InstanceRegistry.gd`: `var _appearance_provider: Callable = Callable()`, `func set_appearance_provider(provider: Callable) -> void`; `spawn_player` adds `"appearance": _appearance_provider.call(peer_id)` when valid (update the comment: appearance is public).
   - `PlayerService.gd`: `var _appearances: Dictionary = {}`; `func appearance_of(peer_id: int) -> Dictionary`: returns the stored dict, creating `AppearanceData.default_for(peer_id).to_dict()` on first use; erase it next to `_states.erase(peer_id)` in the disconnect cleanup (keep it across map transfers). In `spawn_node`, on both server and client, call `player.call("apply_appearance", spawn_data.get("appearance", {}))` right after instantiation.
   - `ServerManager.gd`: next to `set_spawn_function`, `_instances.set_appearance_provider(Callable(_players, "appearance_of"))`.
8. Tests:
   - `test_appearance_data.gd`: round trip `to_dict`/`from_dict`; `from_dict(null)` and `from_dict("x")` give male + empty slots; unknown body type -> male; unknown slot key dropped; non-string / empty / 65-char ids dropped; `default_for(1)` vs `default_for(2)` differ in body type; `default_for(3)` equals `default_for(3)`; every id used by `default_for` has a `.tres` in `data/cosmetics/`.
   - `test_character_rig.gd`: a `CharacterRig` (add it to the test tree if `_ready` is needed, free it after): after `apply` with `default_for(1)` the `hair`, `top`, `mask` nodes each have one `MeshInstance3D` child and `hat` has none; `set_masked(false)` hides `mask`; applying a new appearance without a top clears the `top` node; an unknown id leaves the slot empty and does not crash.
9. `docs/ROADMAP.md`: change the Appearance foundation line to `[x]` and append ` (placeholder primitive meshes until the CC0 base character lands)`.
10. Run Done-when.

## Do not
- No client -> server appearance change request yet (comes with the character creator). No UI. No changes to `ui/` or `docs/ui-design/`. No external assets or downloads. Do not run git.

## Done when
- `godot_console --headless --path . --import`: no script or parse errors (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise).
- `godot_console --headless --path . -s res://tests/run_tests.gd` prints `ALL TESTS PASSED`.
- Final answer: files created/changed, how the Rig lines up with the collision shape, the last 3 test lines, any step you could not do and why.
